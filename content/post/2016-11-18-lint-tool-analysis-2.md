---
date: 2016-11-18T10:46:33+08:00
title: Lint Tool Analysis (2)
tags: ["android"]
published: false
---
Lint工具的源码分析(2)  <!--more-->

**本系列的几篇源码分析文档意义不大，如果你正好也在研究lint源码，或者你想知道前面自定义lint规则中提出的那几个问题，抑或你只是想大致了解下lint的源码都有些什么内容的话，这些文章可能有还些作用，否则看了和没看差不多的，因为这几篇文章只是我在读源码的过程中记录下来的一些零碎的片段，方便以后看的时候能够迅速上手。**

继续上一篇的解析，本篇我们来详细分析下`client.api`包中的重要类。

### 2. client.api包中的重要类

(1) `LintClient`类是指调用lint检查的来源(客户端)，可能是在Android Studio中或者在gradle中，也可能是在终端通过命令行的形式来调用。`LintClient`只是一个抽象类，主要实现类有`IntellijLintClient`，顾名思义它是指在Intellij(Android Studio)中执行lint，它还有两个子类，分别是批量进行lint检查的`BatchLintClient`和针对当前编辑器中单个文件执行lint检查的`EditorLintClient`；另一个实现是`LintClientWrapper`，这个类定义在`LintDriver`中，它并没有具体去实现那些方法，而是采用代理模式的形式进行了一层封装，被封装的`LintClient`可能是`IntellijLintClient`或者`BatchLintClient`或者`EditorLintClient`等。  
**通俗来讲，LintClient是指去调用lint检查的来源(客户端)，它会提供执行lint检查的相关环境信息。**

`LintClient`中定义了一个值为`com.android.tools.lint.bindir`的常量，它是作为键值用来指向lint命令所在的目录，获取这个目录的方法是`getLintBinDir`，它先会去系统属性中查找(用`java -jar xxx -Dcom.android.tools.lint.bindir=value`的形式设置的)，如果没找到的话会再去系统环境变量中查找，有了这个路径的话可以利用相对路径从而方便去获取其他资源，参见其中的`getSdkHome`和`findResource`方法。当我们在终端输入`lint`命令的时候，lint脚本会自动帮我们设置`com.android.tools.lint.bindir`的值，这个我们后面分析lint脚本源码的时候可以看到。

```java
/**
 * Information about the tool embedding the lint analyzer. IDEs and other tools
 * implementing lint support will extend this to integrate logging, displaying errors,
 * etc.
 * <p>
 * <b>NOTE: This is not a public or final API; if you rely on this be prepared
 * to adjust your code for the next tools release.</b>
 */
public abstract class LintClient {
    private static final String PROP_BIN_DIR  = "com.android.tools.lint.bindir";
    ...
    /**
     * Returns the File corresponding to the system property or the environment variable
     * for {@link #PROP_BIN_DIR}.
     * This property is typically set by the SDK/tools/lint[.bat] wrapper.
     * It denotes the path of the wrapper on disk.
     *
     * @return A new File corresponding to {@link LintClient#PROP_BIN_DIR} or null.
     */
    @Nullable
    private static File getLintBinDir() {
        // First check the Java properties (e.g. set using "java -jar ... -Dname=value")
        String path = System.getProperty(PROP_BIN_DIR);
        if (path == null || path.isEmpty()) {
            // If not found, check environment variables.
            path = System.getenv(PROP_BIN_DIR);
        }
        if (path != null && !path.isEmpty()) {
            File file = new File(path);
            if (file.exists()) {
                return file;
            }
        }
        return null;
    }
    ...
    /**
     * Returns the File pointing to the user's SDK install area. This is generally
     * the root directory containing the lint tool (but also platforms/ etc).
     *
     * @return a file pointing to the user's install area
     */
    @Nullable
    public File getSdkHome() {
        File binDir = getLintBinDir();
        if (binDir != null) {
            assert binDir.getName().equals("tools");

            File root = binDir.getParentFile();
            if (root != null && root.isDirectory()) {
                return root;
            }
        }

        String home = System.getenv("ANDROID_HOME"); //$NON-NLS-1$
        if (home != null) {
            return new File(home);
        }

        return null;
    }

    /**
     * Locates an SDK resource (relative to the SDK root directory).
     * <p>
     * TODO: Consider switching to a {@link URL} return type instead.
     *
     * @param relativePath A relative path (using {@link File#separator} to
     *            separate path components) to the given resource
     * @return a {@link File} pointing to the resource, or null if it does not
     *         exist
     */
    @Nullable
    public File findResource(@NonNull String relativePath) {
        File top = getSdkHome();
        if (top == null) {
            throw new IllegalArgumentException("Lint must be invoked with the System property "
                   + PROP_BIN_DIR + " pointing to the ANDROID_SDK tools directory");
        }

        File file = new File(top, relativePath);
        if (file.exists()) {
            return file;
        } else {
            return null;
        }
    }
}
```

`LintClient`中定义了5个抽象方法，其中`repoort`和`log`方法分别用于在lint过程中向调用者(客户端)反馈发现的问题和打印日志信息，这两个方法经常在检查器`Detector`中通过`Context`类对象间接被调用。`getXmlParser`和`getJavaParser`方法分别用来返回解析XML文件和解析Java文件的处理类，`readFile`方法则是用来读取指定的文件内容的。  

```java
/**
 * Report the given issue. This method will only be called if the configuration
 * provided by {@link #getConfiguration(Project,LintDriver)} has reported the corresponding
 * issue as enabled and has not filtered out the issue with its
 * {@link Configuration#ignore(Context,Issue,Location,String)} method.
 * <p>
 * @param context the context used by the detector when the issue was found
 * @param issue the issue that was found
 * @param severity the severity of the issue
 * @param location the location of the issue
 * @param message the associated user message
 * @param format the format of the description and location descriptions
 */
public abstract void report(
        @NonNull Context context,
        @NonNull Issue issue,
        @NonNull Severity severity,
        @NonNull Location location,
        @NonNull String message,
        @NonNull TextFormat format);

/**
 * Send an exception or error message to the log
 *
 * @param severity the severity of the warning
 * @param exception the exception, possibly null
 * @param format the error message using {@link String#format} syntax, possibly null
 *    (though in that case the exception should not be null)
 * @param args any arguments for the format string
 */
public abstract void log(
        @NonNull Severity severity,
        @Nullable Throwable exception,
        @Nullable String format,
        @Nullable Object... args);

/**
 * Returns a {@link XmlParser} to use to parse XML
 *
 * @return a new {@link XmlParser}, or null if this client does not support
 *         XML analysis
 */
@Nullable
public abstract XmlParser getXmlParser();

/**
 * Returns a {@link JavaParser} to use to parse Java
 *
 * @param project the project to parse, if known (this can be used to look up
 *                the class path for type attribution etc, and it can also be used
 *                to more efficiently process a set of files, for example to
 *                perform type attribution for multiple units in a single pass)
 * @return a new {@link JavaParser}, or null if this client does not
 *         support Java analysis
 */
@Nullable
public abstract JavaParser getJavaParser(@Nullable Project project);

/**
 * Reads the given text file and returns the content as a string
 *
 * @param file the file to read
 * @return the string to return, never null (will be empty if there is an
 *         I/O error)
 */
@NonNull
public abstract String readFile(@NonNull File file);
```

`LintClient`中还定义了很多内容，比如下面的`ClassPathInfo`内部类，它用来封装一个Project的各个文件夹，例如源码文件夹，class文件夹，库文件集合等等，以及一个`getClassPath`的方法去获取`ClassPathInfo`数据。  

```java
/**
 * Information about class paths (sources, class files and libraries)
 * usually associated with a project.
 */
protected static class ClassPathInfo {
    private final List<File> mClassFolders;
    private final List<File> mSourceFolders;
    private final List<File> mLibraries;
    private final List<File> mNonProvidedLibraries;
    private final List<File> mTestFolders;

    public ClassPathInfo(
            @NonNull List<File> sourceFolders,
            @NonNull List<File> classFolders,
            @NonNull List<File> libraries,
            @NonNull List<File> nonProvidedLibraries,
            @NonNull List<File> testFolders) {
        mSourceFolders = sourceFolders;
        mClassFolders = classFolders;
        mLibraries = libraries;
        mNonProvidedLibraries = nonProvidedLibraries;
        mTestFolders = testFolders;
    }

    @NonNull
    public List<File> getSourceFolders() {
        return mSourceFolders;
    }

    @NonNull
    public List<File> getClassFolders() {
        return mClassFolders;
    }

    @NonNull
    public List<File> getLibraries(boolean includeProvided) {
        return includeProvided ? mLibraries : mNonProvidedLibraries;
    }

    public List<File> getTestSourceFolders() {
        return mTestFolders;
    }
}

/**
 * Considers the given project as an Eclipse project and returns class path
 * information for the project - the source folder(s), the output folder and
 * any libraries.
 * <p>
 * Callers will not cache calls to this method, so if it's expensive to compute
 * the classpath info, this method should perform its own caching.
 *
 * @param project the project to look up class path info for
 * @return a class path info object, never null
 */
@NonNull
protected ClassPathInfo getClassPath(@NonNull Project project) {
    ClassPathInfo info;
    if (mProjectInfo == null) {
        mProjectInfo = Maps.newHashMap();
        info = null;
    } else {
        info = mProjectInfo.get(project);
    }

    if (info == null) {
        List<File> sources = new ArrayList<File>(2);
        List<File> classes = new ArrayList<File>(1);
        List<File> libraries = new ArrayList<File>();
        // No test folders in Eclipse:
        // https://bugs.eclipse.org/bugs/show_bug.cgi?id=224708
        List<File> tests = Collections.emptyList();

        //将project视为eclipse的project，那么项目根目录下有个.classpath文件，解析这个文件来获取classpath信息
        File projectDir = project.getDir();
        File classpathFile = new File(projectDir, ".classpath"); //$NON-NLS-1$
        if (classpathFile.exists()) {
            String classpathXml = readFile(classpathFile);
            try {
                Document document = XmlUtils.parseDocument(classpathXml, false);
                NodeList tags = document.getElementsByTagName("classpathentry"); //$NON-NLS-1$
                for (int i = 0, n = tags.getLength(); i < n; i++) {
                    Element element = (Element) tags.item(i);
                    String kind = element.getAttribute("kind"); //$NON-NLS-1$
                    List<File> addTo = null;
                    if (kind.equals("src")) {            //$NON-NLS-1$
                        addTo = sources;
                    } else if (kind.equals("output")) {  //$NON-NLS-1$
                        addTo = classes;
                    } else if (kind.equals("lib")) {     //$NON-NLS-1$
                        addTo = libraries;
                    }
                    if (addTo != null) {
                        String path = element.getAttribute("path"); //$NON-NLS-1$
                        File folder = new File(projectDir, path);
                        if (folder.exists()) {
                            addTo.add(folder);
                        }
                    }
                }
            } catch (Exception e) {
                log(null, null);
            }
        }

        // Add in libraries that aren't specified in the .classpath file
        File libs = new File(project.getDir(), LIBS_FOLDER);//添加 libs 目录下的jar文件
        if (libs.isDirectory()) {
            File[] jars = libs.listFiles();
            if (jars != null) {
                for (File jar : jars) {
                    if (endsWith(jar.getPath(), DOT_JAR)
                            && !libraries.contains(jar)) {
                        libraries.add(jar);
                    }
                }
            }
        }

        if (classes.isEmpty()) {
            File folder = new File(projectDir, CLASS_FOLDER);//添加 bin/classes 文件夹
            if (folder.exists()) {
                classes.add(folder);
            } else {//检查是否是maven项目，如果是的话编译得到的class文件是在 target/classes 目录下
                // Maven checks
                folder = new File(projectDir,
                        "target" + File.separator + "classes"); //$NON-NLS-1$ //$NON-NLS-2$
                if (folder.exists()) {
                    classes.add(folder);

                    // If it's maven, also correct the source path, "src" works but
                    // it's in a more specific subfolder
                    if (sources.isEmpty()) {//如果真的是maven项目的话，那么src/main/java目录是一个源码目录
                        File src = new File(projectDir,
                                "src" + File.separator     //$NON-NLS-1$
                                + "main" + File.separator  //$NON-NLS-1$
                                + "java");                 //$NON-NLS-1$
                        if (src.exists()) {
                            sources.add(src);
                        } else {
                            src = new File(projectDir, SRC_FOLDER);
                            if (src.exists()) {
                                sources.add(src);
                            }
                        }

                        //有些class文件是自动生成的，存放在 target/generated-sources/r 目录下
                        File gen = new File(projectDir,
                                "target" + File.separator                  //$NON-NLS-1$
                                + "generated-sources" + File.separator     //$NON-NLS-1$
                                + "r");                                    //$NON-NLS-1$
                        if (gen.exists()) {
                            sources.add(gen);
                        }
                    }
                }
            }
        }

        // Fallback, in case there is no Eclipse project metadata here
        if (sources.isEmpty()) {
            File src = new File(projectDir, SRC_FOLDER);
            if (src.exists()) {
                sources.add(src);
            }
            File gen = new File(projectDir, GEN_FOLDER);
            if (gen.exists()) {
                sources.add(gen);
            }
        }

        info = new ClassPathInfo(sources, classes, libraries, libraries, tests);
        mProjectInfo.put(project, info);
    }

    return info;
}
```

除了`ClassPathInfo`之外，还有很多其他的数据也会在`LintClient`中处理，例如本机的Android SDK的信息以及项目中使用的`buildtool`、`compileSdk`等。  

```java
protected AndroidSdkHandler mSdk;//获取本机的 Android SDK 的相关信息

/**
 * Returns the SDK installation (used to look up platforms etc)
 *
 * @return the SDK if known
 */
@Nullable
public AndroidSdkHandler getSdk() {
    if (mSdk == null) {
        File sdkHome = getSdkHome();
        if (sdkHome != null) {
            mSdk = AndroidSdkHandler.getInstance(sdkHome);
        }
    }

    return mSdk;
}

protected IAndroidTarget[] mTargets;//获取 Android SDK 中已有的 Platform targets

/**
 * Returns all the {@link IAndroidTarget} versions installed in the user's SDK install
 * area.
 *
 * @return all the installed targets
 */
@NonNull
public IAndroidTarget[] getTargets() {//获取 Android SDK 中已有的 Platform targets
    if (mTargets == null) {
        AndroidSdkHandler sdkHandler = getSdk();
        if (sdkHandler != null) {
            ProgressIndicator logger = getRepositoryLogger();
            Collection<IAndroidTarget> targets = sdkHandler.getAndroidTargetManager(logger)
                    .getTargets(logger);
            mTargets = targets.toArray(new IAndroidTarget[targets.size()]);
        } else {
            mTargets = new IAndroidTarget[0];
        }
    }

    return mTargets;
}

/**
 * Returns the compile target to use for the given project
 *
 * @param project the project in question
 *
 * @return the compile target to use to build the given project
 */
@Nullable
public IAndroidTarget getCompileTarget(@NonNull Project project) {//获取项目中使用的 compileSdkVersion
    int buildSdk = project.getBuildSdk();
    IAndroidTarget[] targets = getTargets();
    for (int i = targets.length - 1; i >= 0; i--) {
        IAndroidTarget target = targets[i];
        if (target.isPlatform() && target.getVersion().getApiLevel() == buildSdk) {
            return target;
        }
    }

    return null;
}
/**
 * Returns the specific version of the build tools being used for the given project, if known
 *
 * @param project the project in question
 *
 * @return the build tools version in use by the project, or null if not known
 */
@Nullable
public BuildToolInfo getBuildTools(@NonNull Project project) {//获取 build tools 的信息
    AndroidSdkHandler sdk = getSdk();
    // Build systems like Eclipse and ant just use the latest available
    // build tools, regardless of project metadata. In Gradle, this
    // method is overridden to use the actual build tools specified in the
    // project.
    if (sdk != null) {
        IAndroidTarget compileTarget = getCompileTarget(project);
        if (compileTarget != null) {
            return compileTarget.getBuildToolInfo();
        }
        return sdk.getLatestBuildTool(getRepositoryLogger(), false);
    }

    return null;
}
```

最有意思的是，**lint规则的查找过程也是在`LintClient`中定义的**，下面的代码片段中包含两个重要的查找自定义lint规则的方法。从下面的代码片段中我们终于可以知道为什么放在`~/.android/lint`目录下的自定义lint规则的jar包能够被识别，指定`ANDROID_LINT_JARS`环境变量也能够识别，或者将`lint.jar`放在aar中也能够被识别！  
- **`findGlobalRuleJars`方法会在`~/.android/lint/`目录下找jar包，或者由`$ANDROID_LINT_JARS`环境变量指定的jar包，这些自定义的lint规则都是作用于全局的，也就是对于本机的所有Android工程都生效。**  
- **`findRuleJars`方法是针对指定的project去查找自定义的lint规则，从源码来看，针对project自定义lint规则时只适用于基于Gradle的项目，包括普通的项目和库项目(library project)。**  

```java
/**
 * Finds any custom lint rule jars that should be included for analysis,
 * regardless of project.
 * <p>
 * The default implementation locates custom lint jars in ~/.android/lint/ and
 * in $ANDROID_LINT_JARS
 *
 * @return a list of rule jars (possibly empty).
 */
@SuppressWarnings("MethodMayBeStatic") // Intentionally instance method so it can be overridden
@NonNull
public List<File> findGlobalRuleJars() {
    // Look for additional detectors registered by the user, via
    // (1) an environment variable (useful for build servers etc), and
    // (2) via jar files in the .android/lint directory
    List<File> files = null;
    try {
        String androidHome = AndroidLocation.getFolder();//在 .android/lint 目录下找
        File lint = new File(androidHome + File.separator + "lint"); //$NON-NLS-1$
        if (lint.exists()) {
            File[] list = lint.listFiles();
            if (list != null) {
                for (File jarFile : list) {
                    if (endsWith(jarFile.getName(), DOT_JAR)) {
                        if (files == null) {
                            files = new ArrayList<File>();
                        }
                        files.add(jarFile);
                    }
                }
            }
        }
    } catch (AndroidLocation.AndroidLocationException e) {
        // Ignore -- no android dir, so no rules to load.
    }

    //在环境变量 ANDROID_LINT_JARS 目录下找
    String lintClassPath = System.getenv("ANDROID_LINT_JARS"); //$NON-NLS-1$
    if (lintClassPath != null && !lintClassPath.isEmpty()) {
        String[] paths = lintClassPath.split(File.pathSeparator);
        for (String path : paths) {
            File jarFile = new File(path);
            if (jarFile.exists()) {
                if (files == null) {
                    files = new ArrayList<File>();
                } else if (files.contains(jarFile)) {
                    continue;
                }
                files.add(jarFile);
            }
        }
    }

    return files != null ? files : Collections.<File>emptyList();
}

/**
 * Finds any custom lint rule jars that should be included for analysis
 * in the given project
 *
 * @param project the project to look up rule jars from
 * @return a list of rule jars (possibly empty).
 */
@SuppressWarnings("MethodMayBeStatic") // Intentionally instance method so it can be overridden
@NonNull
public List<File> findRuleJars(@NonNull Project project) {
    if (project.isGradleProject()) {
        if (project.isLibrary()) {//如果是gradle library项目，查找其中的 lint.jar 文件
            AndroidLibrary model = project.getGradleLibraryModel();
            if (model != null) {
                File lintJar = model.getLintJar();
                if (lintJar.exists()) {
                    return Collections.singletonList(lintJar);
                }
            }
        } else if (project.getSubset() != null) {
          //如果该项目有很多个子项目，那就检查当前variant下的依赖中的library project中是否包含了lint.jar
            // Probably just analyzing a single file: we still want to look for custom
            // rules applicable to the file
            List<File> rules = null;
            final Variant variant = project.getCurrentVariant();
            if (variant != null) {
                Collection<AndroidLibrary> libraries = variant.getMainArtifact()
                    .getDependencies().getLibraries();
                for (AndroidLibrary library : libraries) {
                    File lintJar = library.getLintJar();
                    if (lintJar.exists()) {
                        if (rules == null) {
                            rules = Lists.newArrayListWithExpectedSize(4);
                        }
                        rules.add(lintJar);
                    }
                }
                if (rules != null) {
                    return rules;
                }
            }
        } else if (project.getDir().getPath().endsWith(DOT_AAR)) {
            //这种情况是project就是一个aar，查找其中的lint.jar文件
            File lintJar = new File(project.getDir(), "lint.jar"); //$NON-NLS-1$
            if (lintJar.exists()) {
                return Collections.singletonList(lintJar);
            }
        }
    }

    return Collections.emptyList();
}
```

(2) `IssueRegistry`类用来管理需要检查的问题列表，其中还定义了三个特殊的问题：`PARSER_ERROR`表示lint解析文件时出错了；`LINT_ERROR`表示lint检查过程中出现错误，但不是用户代码的错误；`CANCELLED`表示用户取消了lint检查。除此之外，该类中还有一个重要方法`createDetectors`，用来根据指定的Configuration和Scope来创建检查器列表。  
**通俗来讲，IssueRegistry就是lint要检查的问题集合。**

```java
/**
 * Registry which provides a list of checks to be performed on an Android project
 * <p>
 * <b>NOTE: This is not a public or final API; if you rely on this be prepared
 * to adjust your code for the next tools release.</b>
 */
@Beta
public abstract class IssueRegistry {
    private static volatile List<Category> sCategories;//问题的类别列表
    private static volatile Map<String, Issue> sIdToIssue;//问题及其对应的issue
    private static Map<EnumSet<Scope>, List<Issue>> sScopeIssues = Maps.newHashMap();//某个特定的scope内的问题列表

    /**
     * Issue reported by lint (not a specific detector) when it cannot even
     * parse an XML file prior to analysis
     */
    @NonNull
    public static final Issue PARSER_ERROR = Issue.create(
            "ParserError", //$NON-NLS-1$
            "Parser Errors",
            "Lint will ignore any files that contain fatal parsing errors. These may contain " +
            "other errors, or contain code which affects issues in other files.",
            Category.CORRECTNESS,
            10,
            Severity.ERROR,
            DUMMY_IMPLEMENTATION);

    /**
     * Issue reported by lint for various other issues which prevents lint from
     * running normally when it's not necessarily an error in the user's code base.
     */
    @NonNull
    public static final Issue LINT_ERROR = Issue.create(
        "LintError", //$NON-NLS-1$
        "Lint Failure",
        "This issue type represents a problem running lint itself. Examples include " +
        "failure to find bytecode for source files (which means certain detectors " +
        "could not be run), parsing errors in lint configuration files, etc." +
        "\n" +
        "These errors are not errors in your own code, but they are shown to make " +
        "it clear that some checks were not completed.",
        Category.LINT,
        10,
        Severity.ERROR,
        DUMMY_IMPLEMENTATION);

    /**
     * Creates a list of detectors applicable to the given scope, and with the
     * given configuration.
     *
     * @param client the client to report errors to
     * @param configuration the configuration to look up which issues are
     *            enabled etc from
     * @param scope the scope for the analysis, to filter out detectors that
     *            require wider analysis than is currently being performed
     * @param scopeToDetectors an optional map which (if not null) will be
     *            filled by this method to contain mappings from each scope to
     *            the applicable detectors for that scope
     * @return a list of new detector instances
     */
    @NonNull
    final List<? extends Detector> createDetectors(
            @NonNull LintClient client,
            @NonNull Configuration configuration,
            @NonNull EnumSet<Scope> scope,
            @Nullable Map<Scope, List<Detector>> scopeToDetectors) {

        List<Issue> issues = getIssuesForScope(scope);//获取该scope内的问题列表
        if (issues.isEmpty()) {
            return Collections.emptyList();
        }

        //检查器列表detectorClasses和检查器到范围的映射关系detectorToScope
        Set<Class<? extends Detector>> detectorClasses = new HashSet<Class<? extends Detector>>();
        Map<Class<? extends Detector>, EnumSet<Scope>> detectorToScope =
                new HashMap<Class<? extends Detector>, EnumSet<Scope>>();

        for (Issue issue : issues) {//遍历问题列表，取出它们的Detector以及scope集合
            Implementation implementation = issue.getImplementation();
            Class<? extends Detector> detectorClass = implementation.getDetectorClass();
            EnumSet<Scope> issueScope = implementation.getScope();
            if (!detectorClasses.contains(detectorClass)) {
                // Determine if the issue is enabled
                if (!configuration.isEnabled(issue)) {//看configuration中是否开启了这个问题
                    continue;
                }

                assert implementation.isAdequate(scope); // Ensured by getIssuesForScope above
                detectorClass = client.replaceDetector(detectorClass);
                assert detectorClass != null : issue.getId();
                detectorClasses.add(detectorClass);
            }

            if (scopeToDetectors != null) {
                EnumSet<Scope> s = detectorToScope.get(detectorClass);
                if (s == null) {
                    detectorToScope.put(detectorClass, issueScope);
                } else if (!s.containsAll(issueScope)) {
                    EnumSet<Scope> union = EnumSet.copyOf(s);
                    union.addAll(issueScope);
                    detectorToScope.put(detectorClass, union);
                }
            }
        }

        //将detectorToScope转换成scopeToDetectors
        List<Detector> detectors = new ArrayList<Detector>(detectorClasses.size());
        for (Class<? extends Detector> clz : detectorClasses) {
            try {
                Detector detector = clz.newInstance();
                detectors.add(detector);

                if (scopeToDetectors != null) {
                    EnumSet<Scope> union = detectorToScope.get(clz);
                    for (Scope s : union) {
                        List<Detector> list = scopeToDetectors.get(s);
                        if (list == null) {
                            list = new ArrayList<Detector>();
                            scopeToDetectors.put(s, list);
                        }
                        list.add(detector);
                    }

                }
            } catch (Throwable t) {
                client.log(t, "Can't initialize detector %1$s", clz.getName()); //$NON-NLS-1$
            }
        }

        return detectors;
    }
    ...
}
```

`IssueRegistry`类是一个抽象类，它只有一个抽象方法`getIssues`，返回需要检查的问题集合就行，所以特别容易实现。

```java
public abstract List<Issue> getIssues();
```

`IssueRegistry`类有几个特别重要的实现子类，例如`BuiltinIssueRegistry`是系统内置的lint检查器集合，目前共有263个issue；`CompositeIssueRegistry`是一个将很多`IssueRegistry`中的issue整合到一起的IssueRegistry；还有一个很重要的用于加载jar文件中的`IssueRegistry`的类`JarFileIssueRegistry`，前面我们自定义的lint规则的jar包就是由它来解析并加载的。  
**在自定义lint规则生成jar包时我们提到过要在`build.gradle`文件中给jar文件添加`Lint-Registry`的属性值，因为这里会进行检查，如果没有配置的话就不算是合法的lint包。此外，这个类使用了缓存机制来保存已经加载过的jar文件，所以也就导致了我们在自定义lint中出现的更改jar包但是Android Studio并没有更新lint规则的bug！**  

```java
/**
 * <p> An {@link IssueRegistry} for a custom lint rule jar file. The rule jar should provide a
 * manifest entry with the key {@code Lint-Registry} and the value of the fully qualified name of an
 * implementation of {@link IssueRegistry} (with a default constructor). </p>
 *
 * <p> NOTE: The custom issue registry should not extend this file; it should be a plain
 * IssueRegistry! This file is used internally to wrap the given issue registry.</p>
 */
class JarFileIssueRegistry extends IssueRegistry {
    /**
     * Manifest constant for declaring an issue provider. Example: Lint-Registry:
     * foo.bar.CustomIssueRegistry
     */
    private static final String MF_LINT_REGISTRY_OLD = "Lint-Registry"; //$NON-NLS-1$
    private static final String MF_LINT_REGISTRY = "Lint-Registry-v2"; //$NON-NLS-1$

    private static Map<File, SoftReference<JarFileIssueRegistry>> sCache;
    private final List<Issue> myIssues;
    private boolean mHasLegacyDetectors;

    /** True if one or more java detectors were found that use the old Lombok-based API */
    public boolean hasLegacyDetectors() {
        return mHasLegacyDetectors;
    }

    @NonNull
    static JarFileIssueRegistry get(@NonNull LintClient client, @NonNull File jarFile)
            throws IOException, ClassNotFoundException, IllegalAccessException,
            InstantiationException {
        if (sCache == null) {
           sCache = new HashMap<File, SoftReference<JarFileIssueRegistry>>();
        } else {
            SoftReference<JarFileIssueRegistry> reference = sCache.get(jarFile);
            if (reference != null) {
                JarFileIssueRegistry registry = reference.get();
                if (registry != null) {
                    return registry;
                }
            }
        }

        // Ensure that the scope-to-detector map doesn't return stale results
        IssueRegistry.reset();

        JarFileIssueRegistry registry = new JarFileIssueRegistry(client, jarFile);
        sCache.put(jarFile, new SoftReference<JarFileIssueRegistry>(registry));
        return registry;
    }

    private JarFileIssueRegistry(@NonNull LintClient client, @NonNull File file)
            throws IOException, ClassNotFoundException, IllegalAccessException,
                    InstantiationException {
        myIssues = Lists.newArrayList();
        JarFile jarFile = null;
        try {
            //noinspection IOResourceOpenedButNotSafelyClosed
            jarFile = new JarFile(file);
            Manifest manifest = jarFile.getManifest();
            Attributes attrs = manifest.getMainAttributes();
            Object object = attrs.get(new Attributes.Name(MF_LINT_REGISTRY));
            boolean isLegacy = false;
            //检查jar包的MANIFEST.MF文件中是否配置了Lint-Registry-v2或者Lint-Registry属性值
            if (object == null) {
                object = attrs.get(new Attributes.Name(MF_LINT_REGISTRY_OLD));
                //noinspection VariableNotUsedInsideIf
                if (object != null) {
                    // It's an old rule. We don't yet conclude that
                    //   mHasLegacyDetectors=true
                    // because the lint checks may not be Java related.
                    isLegacy = true;
                }
            }
            //如果配置了的话，对应的值就是继承自IssueRegistry的类，我们需要去加载它
            if (object instanceof String) {
                String className = (String) object;
                // Make a class loader for this jar
                URL url = SdkUtils.fileToUrl(file);
                ClassLoader loader = client.createUrlClassLoader(new URL[]{url},
                        JarFileIssueRegistry.class.getClassLoader());
                Class<?> registryClass = Class.forName(className, true, loader);
                IssueRegistry registry = (IssueRegistry) registryClass.newInstance();
                myIssues.addAll(registry.getIssues());

                if (isLegacy) {
                    // If it's an old registry, look through the issues to see if it
                    // provides Java scanning and if so create the old style visitors
                    for (Issue issue : myIssues) {
                        EnumSet<Scope> scope = issue.getImplementation().getScope();
                        if (scope.contains(Scope.JAVA_FILE) || scope.contains(Scope.JAVA_LIBRARIES)
                                || scope.contains(Scope.ALL_JAVA_FILES)) {
                            mHasLegacyDetectors = true;
                            break;
                        }
                    }
                }

                //利用这个ClassLoader去加载jar包中的class
                if (loader instanceof URLClassLoader) {
                    loadAndCloseURLClassLoader(client, file, (URLClassLoader)loader);
                }
            } else {
                client.log(Severity.ERROR, null,
                    "Custom lint rule jar %1$s does not contain a valid registry manifest key " +
                    "(%2$s).\n" +
                    "Either the custom jar is invalid, or it uses an outdated API not supported " +
                    "this lint client", file.getPath(), MF_LINT_REGISTRY);
            }
        } finally {
            if (jarFile != null) {
                jarFile.close();
            }
        }
    }
    ...
}
```

(3) `LintDriver`类是一个核心类，其中汇集了对Android工程或文件进行Lint检查所需的主要元素，包含了上面的`LintClient`和`IssueRegistry`等重要类，还有表示一次lint检查的请求`LintClient`以及监听lint检查过程的`LintListener`集合等数据。  
**通俗来讲，LintDriver包含了一次lint检查时的所有信息，由它来进行lint检查的过程。**

```java
/**
 * Analyzes Android projects and files
 * <p>
 * <b>NOTE: This is not a public or final API; if you rely on this be prepared
 * to adjust your code for the next tools release.</b>
 */
@Beta
public class LintDriver {
    /**
     * Max number of passes to run through the lint runner if requested by
     * {@link #requestRepeat}
     */
    private static final int MAX_PHASES = 3;
    private static final String SUPPRESS_LINT_VMSIG = '/' + SUPPRESS_LINT + ';';
    /** Prefix used by the comment suppress mechanism in Studio/IntelliJ */
    private static final String STUDIO_ID_PREFIX = "AndroidLint";

    private final LintClient mClient;//检查器调用端，可能是android studio或者gradle或者cli
    private LintRequest mRequest;
    private IssueRegistry mRegistry;//问题注册中心
    private volatile boolean mCanceled;
    private EnumSet<Scope> mScope;
    private List<? extends Detector> mApplicableDetectors;
    private Map<Scope, List<Detector>> mScopeDetectors;
    private List<LintListener> mListeners;
    private int mPhase;
    private List<Detector> mRepeatingDetectors;
    private EnumSet<Scope> mRepeatScope;
    private Project[] mCurrentProjects;
    private Project mCurrentProject;
    private boolean mAbbreviating = true;
    private boolean mParserErrors;
    private Map<Object,Object> mProperties;
    /** Whether we need to look for legacy (old Lombok-based Java API) detectors */
    private boolean mRunCompatChecks = true;
    ...
}
```

前面我们在`LintClient`中看到了lint工具是如何查找自定义的lint规则，但是并没有看到这些规则是如何注册到`IssueRegistry`上去的，而这个艰巨的任务实际上是在`LintDriver`中完成的，主要流程都在方法`registerCustomDetectors`中。  

```java
private Set<Issue> myCustomIssues;//自定义的lint规则集合

/**
* Returns true if the given issue is an issue that was loaded as a custom rule
* (e.g. a 3rd-party library provided the detector, it's not built in)
*
* @param issue the issue to be looked up
* @return true if this is a custom (non-builtin) check
*/
public boolean isCustomIssue(@NonNull Issue issue) {//判断某个issue是否是自定义的issue
   return myCustomIssues != null && myCustomIssues.contains(issue);
}

//注册自定义的检查器，检查器来源于参数中指定的projects中
private void registerCustomDetectors(Collection<Project> projects) {
   // Look at the various projects, and if any of them provide a custom
   // lint jar, "add" them (this will replace the issue registry with
   // a CompositeIssueRegistry containing the original issue registry
   // plus JarFileIssueRegistry instances for each lint jar
   Set<File> jarFiles = Sets.newHashSet();
   for (Project project : projects) {//遍历所有的project以及它们的library project，找出其中所有的lint.jar文件
       jarFiles.addAll(mClient.findRuleJars(project));
       for (Project library : project.getAllLibraries()) {
           jarFiles.addAll(mClient.findRuleJars(library));
       }
   }

   jarFiles.addAll(mClient.findGlobalRuleJars());//查找全局的自定义的lint规则的jar包

   if (!jarFiles.isEmpty()) {
       List<IssueRegistry> registries = Lists.newArrayListWithExpectedSize(jarFiles.size());
       registries.add(mRegistry);
       for (File jarFile : jarFiles) {
           try {
               JarFileIssueRegistry registry = JarFileIssueRegistry.get(mClient, jarFile);
               if (registry.hasLegacyDetectors()) {
                   mRunCompatChecks = true;
               }
               if (myCustomIssues == null) {
                   myCustomIssues = Sets.newHashSet();
               }
               myCustomIssues.addAll(registry.getIssues());
               registries.add(registry);
           } catch (Throwable e) {
               mClient.log(e, "Could not load custom rule jar file %1$s", jarFile);
           }
       }
       if (registries.size() > 1) { // the first item is mRegistry itself
           mRegistry = new CompositeIssueRegistry(registries);
       }
   }
}
```

`LintDriver`还有一个重要的方法就是`analyze`，lint检查就是从这里正式开始的。其中的`mRequest`是`LintRequest`对象，类似HTTPRequest一样，表示一次lint检查的请求，它包含了这次lint检查的一些基本信息。其中还调用了`registerCustomDetectors`方法，这个方法就是用来注册那些自定义的lint规则的。此外，其中会遍历所有的project，然后调用`runExtraPhases`方法就该project进行lint检查。

```java
/** Runs the driver to analyze the requested files */
private void analyze() {
    mCanceled = false;
    mScope = mRequest.getScope();
    assert mScope == null || !mScope.contains(Scope.ALL_RESOURCE_FILES) ||
            mScope.contains(Scope.RESOURCE_FILE);

    Collection<Project> projects;
    try {
        projects = mRequest.getProjects();
        if (projects == null) {
            projects = computeProjects(mRequest.getFiles());
        }
    } catch (CircularDependencyException e) {
        mCurrentProject = e.getProject();
        if (mCurrentProject != null) {
            Location location = e.getLocation();
            File file = location != null ? location.getFile() : mCurrentProject.getDir();
            Context context = new Context(this, mCurrentProject, null, file);
            context.report(IssueRegistry.LINT_ERROR, e.getLocation(), e.getMessage());
            mCurrentProject = null;
        }
        return;
    }
    if (projects.isEmpty()) {
        mClient.log(null, "No projects found for %1$s", mRequest.getFiles().toString());
        return;
    }
    if (mCanceled) {
        return;
    }
    registerCustomDetectors(projects);//注册自定义的lint检查器
    if (mScope == null) {//如果范围为空，那么就根据projects来推断范围
        mScope = Scope.infer(projects);
    }
    fireEvent(EventType.STARTING, null);//fireEvent用于触发相应的事件，通知LintListener
    for (Project project : projects) {
        mPhase = 1;
        Project main = mRequest.getMainProject(project);
        // The set of available detectors varies between projects
        computeDetectors(project);
        if (mApplicableDetectors.isEmpty()) {
            // No detectors enabled in this project: skip it
            continue;
        }
        checkProject(project, main);
        if (mCanceled) {
            break;
        }
        runExtraPhases(project, main);
    }
    fireEvent(mCanceled ? EventType.CANCELED : EventType.COMPLETED, null);
}
```

`runExtraPhases`方法中会调用`checkProject`方法去对指定的project进行lint检查，其中调用了另一个核心方法`runFileDetectors`。

```java
private void checkProject(@NonNull Project project, @NonNull Project main) {
    File projectDir = project.getDir();

    Context projectContext = new Context(this, project, null, projectDir);
    fireEvent(EventType.SCANNING_PROJECT, projectContext);

    List<Project> allLibraries = project.getAllLibraries();
    Set<Project> allProjects = new HashSet<Project>(allLibraries.size() + 1);
    allProjects.add(project);
    allProjects.addAll(allLibraries);
    mCurrentProjects = allProjects.toArray(new Project[allProjects.size()]);

    mCurrentProject = project;
    for (Detector check : mApplicableDetectors) {
        check.beforeCheckProject(projectContext);
        if (mCanceled) {
            return;
        }
    }

    assert mCurrentProject == project;
    runFileDetectors(project, main);
    if (!Scope.checkSingleFile(mScope)) {
        List<Project> libraries = project.getAllLibraries();
        for (Project library : libraries) {
            Context libraryContext = new Context(this, library, project, projectDir);
            fireEvent(EventType.SCANNING_LIBRARY_PROJECT, libraryContext);
            mCurrentProject = library;

            for (Detector check : mApplicableDetectors) {
                check.beforeCheckLibraryProject(libraryContext);
                if (mCanceled) {
                    return;
                }
            }
            assert mCurrentProject == library;
            runFileDetectors(library, main);
            if (mCanceled) {
                return;
            }

            assert mCurrentProject == library;
            for (Detector check : mApplicableDetectors) {
                check.afterCheckLibraryProject(libraryContext);
                if (mCanceled) {
                    return;
                }
            }
        }
    }

    mCurrentProject = project;
    for (Detector check : mApplicableDetectors) {
        check.afterCheckProject(projectContext);
        if (mCanceled) {
            return;
        }
    }

    if (mCanceled) {
        mClient.report(
            projectContext,
            // Must provide an issue since API guarantees that the issue parameter
            IssueRegistry.CANCELLED,
            Severity.INFORMATIONAL,
            Location.create(project.getDir()),
            "Lint canceled by user", TextFormat.RAW);
    }
    mCurrentProjects = null;
}
```

方法`runFileDetectors`的作用就是对文件进行lint检查，上一篇我们提到过lint检查的顺序，从下面的代码我们也可以看出检查的顺序依次是`Manifest文件 => Resource文件 => Java源码文件 => Java Class文件 => Gradle文件 => Generic文件 => Proguard文件 => Property文件`。

```java
private void runFileDetectors(@NonNull Project project, @Nullable Project main) {
    // Look up manifest information (but not for library projects)
    if (project.isAndroidProject()) {
      //如果是Android项目的话，使用XmlParser去读取Manifest.xml文件的信息
        for (File manifestFile : project.getManifestFiles()) {
            XmlParser parser = mClient.getXmlParser();
            if (parser != null) {
                XmlContext context = new XmlContext(this, project, main, manifestFile, null, parser);
                context.document = parser.parseXml(context);
                if (context.document != null) {
                    try {
                        project.readManifest(context.document);

                        //执行lint检查时会先获取Scope.MANIFEST下的所有detector
                        //然后创建ResourceVisitor去对文件进行lint检查
                        if ((!project.isLibrary() || (main != null
                                && main.isMergingManifests()))
                                && mScope.contains(Scope.MANIFEST)) {
                            List<Detector> detectors = mScopeDetectors.get(Scope.MANIFEST);
                            if (detectors != null) {
                                ResourceVisitor v = new ResourceVisitor(parser, detectors, null);
                                fireEvent(EventType.SCANNING_FILE, context);
                                v.visitFile(context, manifestFile);
                            }
                        }
                    } finally {
                      if (context.document != null) { // else: freed by XmlVisitor above
                          parser.dispose(context, context.document);
                      }
                    }
                }
            }
        }

        //检查资源文件
        // Process both Scope.RESOURCE_FILE and Scope.ALL_RESOURCE_FILES detectors together
        // in a single pass through the resource directories.
        if (mScope.contains(Scope.ALL_RESOURCE_FILES)
                || mScope.contains(Scope.RESOURCE_FILE)
                || mScope.contains(Scope.RESOURCE_FOLDER)
                || mScope.contains(Scope.BINARY_RESOURCE_FILE)) {
            List<Detector> dirChecks = mScopeDetectors.get(Scope.RESOURCE_FOLDER);
            List<Detector> binaryChecks = mScopeDetectors.get(Scope.BINARY_RESOURCE_FILE);
            List<Detector> checks = union(mScopeDetectors.get(Scope.RESOURCE_FILE),
                    mScopeDetectors.get(Scope.ALL_RESOURCE_FILES));
            boolean haveXmlChecks = checks != null && !checks.isEmpty();
            List<ResourceXmlDetector> xmlDetectors;
            if (haveXmlChecks) {
                xmlDetectors = new ArrayList<ResourceXmlDetector>(checks.size());
                for (Detector detector : checks) {
                    if (detector instanceof ResourceXmlDetector) {
                        xmlDetectors.add((ResourceXmlDetector) detector);
                    }
                }
                haveXmlChecks = !xmlDetectors.isEmpty();
            } else {
                xmlDetectors = Collections.emptyList();
            }
            if (haveXmlChecks
                    || dirChecks != null && !dirChecks.isEmpty()
                    || binaryChecks != null && !binaryChecks.isEmpty()) {
                List<File> files = project.getSubset();
                if (files != null) {
                    checkIndividualResources(project, main, xmlDetectors, dirChecks,
                            binaryChecks, files);
                } else {
                    List<File> resourceFolders = project.getResourceFolders();
                    if (!resourceFolders.isEmpty()) {
                        for (File res : resourceFolders) {
                            checkResFolder(project, main, res, xmlDetectors, dirChecks,
                                    binaryChecks);
                        }
                    }
                }
            }
        }

        if (mCanceled) {
            return;
        }
    }

    //检查java文件
    if (mScope.contains(Scope.JAVA_FILE) || mScope.contains(Scope.ALL_JAVA_FILES)) {
        List<Detector> checks = union(mScopeDetectors.get(Scope.JAVA_FILE),
                mScopeDetectors.get(Scope.ALL_JAVA_FILES));
        if (checks != null && !checks.isEmpty()) {
            List<File> files = project.getSubset();
            if (files != null) {
                checkIndividualJavaFiles(project, main, checks, files);
            } else {
                List<File> sourceFolders = project.getJavaSourceFolders();
                if (mScope.contains(Scope.TEST_SOURCES)) {
                    List<File> testFolders = project.getTestSourceFolders();
                    if (!testFolders.isEmpty()) {
                        List<File> combined = Lists.newArrayListWithExpectedSize(
                                sourceFolders.size() + testFolders.size());
                        combined.addAll(sourceFolders);
                        combined.addAll(testFolders);
                        sourceFolders = combined;
                    }
                }

                checkJava(project, main, sourceFolders, checks);

            }
        }
    }

    if (mCanceled) {
        return;
    }

    //检查class文件
    if (mScope.contains(Scope.CLASS_FILE)
            || mScope.contains(Scope.ALL_CLASS_FILES)
            || mScope.contains(Scope.JAVA_LIBRARIES)) {
        checkClasses(project, main);
    }

    if (mCanceled) {
        return;
    }

    //检查gradle文件
    if (mScope.contains(Scope.GRADLE_FILE)) {
        checkBuildScripts(project, main);
    }

    if (mCanceled) {
        return;
    }

    //检查其他的Generic文件
    if (mScope.contains(Scope.OTHER)) {
        List<Detector> checks = mScopeDetectors.get(Scope.OTHER);
        if (checks != null) {
            OtherFileVisitor visitor = new OtherFileVisitor(checks);
            visitor.scan(this, project, main);
        }
    }

    if (mCanceled) {
        return;
    }

    //检查proguard文件
    if (project == main && mScope.contains(Scope.PROGUARD_FILE) &&
            project.isAndroidProject()) {
        checkProGuard(project, main);
    }

    //检查property文件
    if (project == main && mScope.contains(Scope.PROPERTY_FILE)) {
        checkProperties(project, main);
    }
}
```

下面我们看下Java文件是如何进行lint检查的，我们在下一篇将会详细介绍这部分代码的实现细节。

```java
private void checkIndividualJavaFiles(//检查单个的Java文件
        @NonNull Project project,
        @Nullable Project main,
        @NonNull List<Detector> checks,
        @NonNull List<File> files) {

    JavaParser javaParser = mClient.getJavaParser(project);
    if (javaParser == null) {
        mClient.log(null, "No java parser provided to lint: not running Java checks");
        return;
    }

    List<JavaContext> contexts = Lists.newArrayListWithExpectedSize(files.size());
    for (File file : files) {
        if (file.isFile() && file.getPath().endsWith(DOT_JAVA)) {
            contexts.add(new JavaContext(this, project, main, file, javaParser));
        }
    }

    if (contexts.isEmpty()) {
        return;
    }

    visitJavaFiles(checks, javaParser, contexts);
}

//访问java文件，进行lint检查
private void visitJavaFiles(@NonNull List<Detector> checks, JavaParser javaParser,
        List<JavaContext> contexts) {
    // Temporary: we still have some builtin checks that aren't migrated to
    // PSI. Until that's complete, remove them from the list here
    //List<Detector> scanners = checks;
    //当前新版的Java检查器都是实现了JavaPsiScanner接口，由它可以创建JavaPsiVisitor
    List<Detector> scanners = Lists.newArrayListWithCapacity(checks.size());
    for (Detector detector : checks) {
        if (detector instanceof Detector.JavaPsiScanner) {
            scanners.add(detector);
        }
    }

    JavaPsiVisitor visitor = new JavaPsiVisitor(javaParser, scanners);
    visitor.prepare(contexts);
    for (JavaContext context : contexts) {
        fireEvent(EventType.SCANNING_FILE, context);
        visitor.visitFile(context);
        if (mCanceled) {
            return;
        }
    }

    visitor.dispose();

    //下面是为了兼容以前版本的Java检查器而做的检查，它会创建JavaScanner以及JavaVisitor去对文件进行检查
    // Only if the user is using some custom lint rules that haven't been updated
    // yet noinspection ConstantConditions
    if (mRunCompatChecks) {
        // Filter the checks to only those that implement JavaScanner
        List<Detector> filtered = Lists.newArrayListWithCapacity(checks.size());
        for (Detector detector : checks) {
            if (detector instanceof Detector.JavaScanner) {
                filtered.add(detector);
            }
        }

        if (!filtered.isEmpty()) {
            List<String> detectorNames = Lists.newArrayListWithCapacity(filtered.size());
            for (Detector detector : filtered) {
                detectorNames.add(detector.getClass().getName());
            }
            Collections.sort(detectorNames);
            JavaVisitor oldVisitor = new JavaVisitor(javaParser, filtered);

            oldVisitor.prepare(contexts);
            for (JavaContext context : contexts) {
                fireEvent(EventType.SCANNING_FILE, context);
                oldVisitor.visitFile(context);
                if (mCanceled) {
                    return;
                }
            }
            oldVisitor.dispose();
        }
    }
}
```

未完待续...
