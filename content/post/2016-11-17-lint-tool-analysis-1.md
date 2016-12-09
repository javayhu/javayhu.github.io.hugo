---
date: 2016-11-17T10:46:33+08:00
title: Lint Tool Analysis (1)
tags: ["android"]
published: false
---
Lint工具的源码分析(1)  <!--more-->

**本系列的几篇源码分析文档意义不大，如果你正好也在研究lint源码，或者你想知道前面自定义lint规则中提出的那几个问题，抑或你只是想大致了解下lint的源码都有些什么内容的话，这些文章可能有还些作用，否则看了和没看差不多的，因为这几篇文章只是我在读源码的过程中记录下来的一些零碎的片段，方便以后看的时候能够迅速上手。**

在前面的[Custom Lint in Action](/blog/2016/11/10/custom-lint-in-action/)中我们了解到将自定义的lint规则打包成jar，然后放在`~/.android/lint/`目录下的话，我们就能够应用这些规则对工程进行静态代码扫描了。但是，这是为什么呢？为什么是打包成jar？为什么是放在那个目录下？为什么放在那里就能够被识别且被应用了呢？要揭晓这些问题的答案，我们就必须要去阅读lint工具的源码一探究竟啦！

**Lint检查归根结底是对某些文件可能存在的某些问题利用静态扫描源文件的方式去检查看是否真的存在那些问题的过程。**  
针对这个需求，我们需要控制哪些文件需要被检查(Scope)、哪些问题需要进行检查(IssueRegistry)、该问题应如何进行检查(Detector)以及源代码文件如何进行静态扫描(Scanner)等内容进行封装，其实lint工具的源码就是这么设计和封装的。

`lint`工具源码主要分成两部分：`lint-api`和`lint-checks`，前者主要是lint的核心API，后者是利用API定义的检查器。其中`lint-api`又分为`detector.api`和`client.api`这两个包，其中`detector.api`这个包主要是和lint检查器相关的类，`client.api`这个包主要是和调用lint检查有关的类。由于内容实在太多，故分成多篇分别来解析下，本篇主要解析的是`detector.api`包中的重要类。

### 1. detector.api包中的重要类

(1) `Scope`枚举类表示lint检查时需要检查的文件范围，例如`RESOURCE_FILE，JAVA_FILE，CLASS_FILE，GRADLE_FILE`等，各项含义与下面的代码片段类似。该类中的`infer`方法是用来推断选定的项目有哪些文件范围需要检查(根据文件名判断)，`checkSingleFile`方法是用来判断是检查单个文件还是检查整个项目所有的该类型文件。  
**通俗来讲，Scope指的就是哪个文件或者哪些文件需要被检查。**

```java
/**
 * The scope of a detector is the set of files a detector must consider when
 * performing its analysis. This can be used to determine when issues are
 * potentially obsolete, whether a detector should re-run on a file save, etc.
 * <p>
 * <b>NOTE: This is not a public or final API; if you rely on this be prepared
 * to adjust your code for the next tools release.</b>
 */
@Beta
public enum Scope {
    /**
     * The analysis only considers a single XML resource file at a time.
     * <p>
     * Issues which are only affected by a single resource file can be checked
     * for incrementally when a file is edited.
     */
    RESOURCE_FILE,//检查单个资源文件，可以增量式检查

    /**
     * The analysis only considers a single binary (typically a bitmap) resource file at a time.
     * <p>
     * Issues which are only affected by a single resource file can be checked
     * for incrementally when a file is edited.
     */
    BINARY_RESOURCE_FILE,//检查二进制形式的资源文件，例如bitmap

    /**
     * The analysis considers the resource folders (which also includes asset folders)
     */
    RESOURCE_FOLDER,//检查资源目录，包括asset目录

    /**
     * The analysis considers <b>all</b> the resource file. This scope must not
     * be used in conjunction with {@link #RESOURCE_FILE}; an issue scope is
     * either considering just a single resource file or all the resources, not
     * both.
     */
    ALL_RESOURCE_FILES,//检查所有的资源文件，这个和RESOURCE_FILE是互斥的，两者只能设置为其中一个
    ...//其他类型的scope
}
```

(2) `Context`类表示lint检查时的上下文环境，包括需要进行分析的项目和文件的信息以及lint规则的配置信息，例如`Project，File，LintDriver，Configuration`等，详情请参考下面的代码及其注释理解。其子类包括`JavaContext，ClassContext，XmlContext，ResourceContext`，顾名思义，JavaContext就是用来检查Java文件的Context。  
**通俗来讲，Context指的就是lint检查时的上下文信息。**

```java
/**
 * Context passed to the detectors during an analysis run. It provides
 * information about the file being analyzed, it allows shared properties (so
 * the detectors can share results), etc.
 * <p>
 * <b>NOTE: This is not a public or final API; if you rely on this be prepared
 * to adjust your code for the next tools release.</b>
 */
public class Context {
    /**
     * The file being checked. Note that this may not always be to a concrete
     * file. For example, in the {@link Detector#beforeCheckProject(Context)}
     * method, the context file is the directory of the project.
     */
    public final File file;//被检查的文件

    /** The driver running through the checks */
    protected final LintDriver mDriver;//运行所有检查的driver

    /** The project containing the file being checked */
    @NonNull
    private final Project mProject;//包含需要检查的文件的项目

    /**
     * The "main" project. For normal projects, this is the same as {@link #mProject},
     * but for library projects, it's the root project that includes (possibly indirectly)
     * the various library projects and their library projects.
     * <p>
     * Note that this is a property on the {@link Context}, not the
     * {@link Project}, since a library project can be included from multiple
     * different top level projects, so there isn't <b>one</b> main project,
     * just one per main project being analyzed with its library projects.
     */
    private final Project mMainProject;//主项目，在普通项目中它和库项目相同，但是对于库项目来说，主项目是包含多个不同库项目的根项目

    /** The current configuration controlling which checks are enabled etc */
    private final Configuration mConfiguration;//检查器的配置信息，例如哪些检查器开启或关闭了

    /** The contents of the file */
    private String mContents;//文件的内容

    /** Map of properties to share results between detectors */
    private Map<String, Object> mProperties;//用于在检查器之间共享数据的键值对

    /** Whether this file contains any suppress markers (null means not yet determined) */
    private Boolean mContainsCommentSuppress;//文件是否包含suppress lint相关的注释，null表示还不确定
    ...
}
```

(2.1) `Project`类表示一个项目包含的内容，例如项目的路径，名称，android版本信息，sdk信息，buildtool信息，gradle版本，以及其他的各种类型的文件以及文件集合等信息。

```java
/**
 * A project contains information about an Android project being scanned for
 * Lint errors.
 * <p>
 * <b>NOTE: This is not a public or final API; if you rely on this be prepared
 * to adjust your code for the next tools release.</b>
 */
@Beta
public class Project {
    protected final LintClient mClient;//下一篇会详细分析这个 LintClient
    protected final File mDir;
    protected final File mReferenceDir;
    protected Configuration mConfiguration;
    protected String mPackage;
    protected int mBuildSdk = -1;
    protected IAndroidTarget mTarget;

    protected AndroidVersion mManifestMinSdk = AndroidVersion.DEFAULT;
    protected AndroidVersion mManifestTargetSdk = AndroidVersion.DEFAULT;

    protected boolean mLibrary;
    protected String mName;
    protected String mProguardPath;
    protected boolean mMergeManifests;

    /** The SDK info, if any */
    protected SdkInfo mSdkInfo;

    /**
     * If non null, specifies a non-empty list of specific files under this
     * project which should be checked.
     */
    protected List<File> mFiles;
    protected List<File> mProguardFiles;
    protected List<File> mGradleFiles;
    protected List<File> mManifestFiles;
    protected List<File> mJavaSourceFolders;
    protected List<File> mJavaClassFolders;
    protected List<File> mNonProvidedJavaLibraries;
    protected List<File> mJavaLibraries;
    protected List<File> mTestSourceFolders;
    protected List<File> mResourceFolders;
    protected List<File> mAssetFolders;
    protected List<Project> mDirectLibraries;
    protected List<Project> mAllLibraries;
    protected boolean mReportIssues = true;
    protected Boolean mGradleProject;
    protected Boolean mSupportLib;
    protected Boolean mAppCompat;
    protected GradleVersion mGradleVersion;
    private Map<String, String> mSuperClassMap;
    private ResourceVisibilityLookup mResourceVisibility;
    private BuildToolInfo mBuildTools;
    ...
}
```

(2.2) `Configuration`类是一个抽象类，主要用来判断或者配置某个lint检查规则是否开启、是否忽略等。

```java
/**
 * Lint configuration for an Android project such as which specific rules to include,
 * which specific rules to exclude, and which specific errors to ignore.
 * <p>
 * <b>NOTE: This is not a public or final API; if you rely on this be prepared
 * to adjust your code for the next tools release.</b>
 */
@Beta
public abstract class Configuration {
    /**
     * Checks whether this issue should be ignored because the user has already
     * suppressed the error? Note that this refers to individual issues being
     * suppressed/ignored, not a whole detector being disabled via something
     * like {@link #isEnabled(Issue)}.
     *
     * @param context the context used by the detector when the issue was found
     * @param issue the issue that was found
     * @param location the location of the issue
     * @param message the associated user message
     * @return true if this issue should be suppressed
     */
    public boolean isIgnored(
            @NonNull Context context,
            @NonNull Issue issue,
            @Nullable Location location,
            @NonNull String message) {
        return false;//有些issue是开启了，但是用户可能以某种方式suppress了这种错误
    }

    /**
     * Returns false if the given issue has been disabled. This is just
     * a convenience method for {@code getSeverity(issue) != Severity.IGNORE}.
     *
     * @param issue the issue to check
     * @return false if the issue has been disabled
     */
    public boolean isEnabled(@NonNull Issue issue) {
        return getSeverity(issue) != Severity.IGNORE;//只要严重程度不是IGNORE的话那就是开启了
    }
    ...
}
```

`Configuration`有个默认的实现`DefaultConfiguration`，在`client.api`包中，它的主要作用是读写项目根目录下的`lint.xml`配置文件，下面是lint.xml文件的一个例子。  

```xml
<?xml version="1.0" encoding="UTF-8"?>
<lint>
    <!-- Disable the given check in this project -->
    <issue id="IconMissingDensityFolder" severity="ignore" />

    <!-- Ignore the ObsoleteLayoutParam issue in the specified files -->
    <issue id="ObsoleteLayoutParam">
        <ignore regexp="res/.*/activation.xml" />
    </issue>

    <!-- Ignore the UselessLeaf issue in the specified file -->
    <issue id="UselessLeaf">
        <ignore path="res/layout/main.xml" />
    </issue>

    <!-- Change the severity of hardcoded strings to "error" -->
    <issue id="HardcodedText" severity="error" />
</lint>
```

下面的代码片段中包含了读取lint配置文件的实现过程，可以结合注释以及上面的lint.xml文件的例子来看，处理流程相对还比较清晰。  

```java
//默认的Configuration的实现
/**
 * Default implementation of a {@link Configuration} which reads and writes
 * configuration data into {@code lint.xml} in the project directory.
 * <p>
 * <b>NOTE: This is not a public or final API; if you rely on this be prepared
 * to adjust your code for the next tools release.</b>
 */
@Beta
public class DefaultConfiguration extends Configuration {
    private final LintClient mClient;
    /** Default name of the configuration file */
    public static final String CONFIG_FILE_NAME = "lint.xml"; //$NON-NLS-1$

    // Lint XML File => 定义lint.xml文件中的元素标签
    @NonNull
    private static final String TAG_ISSUE = "issue"; //$NON-NLS-1$
    @NonNull
    private static final String ATTR_ID = "id"; //$NON-NLS-1$
    @NonNull
    private static final String ATTR_SEVERITY = "severity"; //$NON-NLS-1$
    @NonNull
    private static final String ATTR_PATH = "path"; //$NON-NLS-1$
    @NonNull
    private static final String ATTR_REGEXP = "regexp"; //$NON-NLS-1$
    @NonNull
    private static final String TAG_IGNORE = "ignore"; //$NON-NLS-1$
    @NonNull
    private static final String VALUE_ALL = "all"; //$NON-NLS-1$

    private final Configuration mParent;
    private final Project mProject;
    private final File mConfigFile;
    private boolean mBulkEditing;

    /** Map from id to list of project-relative paths for suppressed warnings */
    private Map<String, List<String>> mSuppressed;//指定issue有哪些不检查的路径列表

    /** Map from id to regular expressions. */
    @Nullable
    private Map<String, List<Pattern>> mRegexps;

    /**
     * Map from id to custom {@link Severity} override
     */
    private Map<String, Severity> mSeverity;//指定issue对应的严重程度
    ...
    //从lint配置文件中读取lint规则的配置信息
    private void readConfig() {
        mSuppressed = new HashMap<String, List<String>>();
        mSeverity = new HashMap<String, Severity>();

        if (!mConfigFile.exists()) {
            return;
        }

        try {
            Document document = XmlUtils.parseUtfXmlFile(mConfigFile, false);
            NodeList issues = document.getElementsByTagName(TAG_ISSUE);
            Splitter splitter = Splitter.on(',').trimResults().omitEmptyStrings();
            for (int i = 0, count = issues.getLength(); i < count; i++) {//遍历issue
                Node node = issues.item(i);
                Element element = (Element) node;
                String idList = element.getAttribute(ATTR_ID);//读取id属性值
                if (idList.isEmpty()) {
                    formatError("Invalid lint config file: Missing required issue id attribute");
                    continue;
                }
                Iterable<String> ids = splitter.split(idList);//id属性值中可能存在多个id，先将其分开来

                //下面这部分是处理severity属性值的配置
                NamedNodeMap attributes = node.getAttributes();
                for (int j = 0, n = attributes.getLength(); j < n; j++) {
                    Node attribute = attributes.item(j);
                    String name = attribute.getNodeName();
                    String value = attribute.getNodeValue();
                    if (ATTR_ID.equals(name)) {
                        // already handled
                    } else if (ATTR_SEVERITY.equals(name)) {
                        for (Severity severity : Severity.values()) {
                            if (value.equalsIgnoreCase(severity.name())) {
                                for (String id : ids) {
                                    mSeverity.put(id, severity);
                                }
                                break;
                            }
                        }
                    } else {
                        formatError("Unexpected attribute \"%1$s\"", name);
                    }
                }

                //下面这部分是处理该issue的ignore路径的配置，配置ignore有两种方式，一种是path，另一种是regexp (正则匹配)
                // Look up ignored errors
                NodeList childNodes = element.getChildNodes();
                if (childNodes.getLength() > 0) {
                    for (int j = 0, n = childNodes.getLength(); j < n; j++) {
                        Node child = childNodes.item(j);
                        if (child.getNodeType() == Node.ELEMENT_NODE) {
                            Element ignore = (Element) child;
                            String path = ignore.getAttribute(ATTR_PATH);
                            if (path.isEmpty()) {//regexp的形式
                                String regexp = ignore.getAttribute(ATTR_REGEXP);
                                if (regexp.isEmpty()) {
                                    formatError("Missing required attribute %1$s or %2$s under %3$s",
                                        ATTR_PATH, ATTR_REGEXP, idList);
                                } else {
                                    addRegexp(idList, ids, n, regexp, false);
                                }
                            } else {//path的形式
                                // Normalize path format to File.separator. Also
                                // handle the file format containing / or \.
                                if (File.separatorChar == '/') {
                                    path = path.replace('\\', '/');
                                } else {
                                    path = path.replace('/', File.separatorChar);
                                }

                                if (path.indexOf('*') != -1) {
                                    String regexp = globToRegexp(path);
                                    addRegexp(idList, ids, n, regexp, false);
                                } else {
                                    for (String id : ids) {
                                        List<String> paths = mSuppressed.get(id);
                                        if (paths == null) {
                                            paths = new ArrayList<String>(n / 2 + 1);
                                            mSuppressed.put(id, paths);
                                        }
                                        paths.add(path);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (SAXParseException e) {
            formatError(e.getMessage());
        } catch (Exception e) {
            mClient.log(e, null);
        }
    }
}
```

(2.3) `LintDriver`类很大很复杂，而且是在`client.api`包中，我们将在下一节介绍。

(3) `Detector`类表示lint检查器，也就是用来发现文件中是否存在某个问题的检查器，自定义lint规则就是自定义相应的Detector。针对不同类型文件的检查器会按照预先定义的顺序依次进行检查，检查的顺序依次是`Manifest文件 => Resource文件 => Java源码文件 => Java Class文件 => Gradle文件 => Generic文件 => Proguard文件 => Property文件`。Detector类中定义了很多检查器通用的一些方法，比如下面代码片段中的`visitMethod`、`visitConstructor`等等。  
**通俗来讲，Detector指的就是一个个的lint检查器。**

```java
public class Detector {
    ...
    @SuppressWarnings({"UnusedParameters", "unused", "javadoc"})
    public void visitMethod(@NonNull JavaContext context, @Nullable JavaElementVisitor visitor,
            @NonNull PsiMethodCallExpression call, @NonNull PsiMethod method) {
    }//访问一个普通的方法

    @SuppressWarnings({"UnusedParameters", "unused", "javadoc"})
    public void visitConstructor(
            @NonNull JavaContext context,
            @Nullable JavaElementVisitor visitor,
            @NonNull PsiNewExpression node,
            @NonNull PsiMethod constructor) {
    }//访问一个构造函数

    @SuppressWarnings({"UnusedParameters", "unused", "javadoc"})
    public void visitResourceReference(@NonNull JavaContext context,
            @Nullable JavaElementVisitor visitor, @NonNull PsiElement node,
            @NonNull ResourceType type, @NonNull String name, boolean isFramework) {
    }//访问一个资源引用
    ...
}
```

除此之外，`Detector`类中还定义了很多不同类型文件的扫描器(Scanner)接口，例如`JavaPsiScanner，ClassScanner，ResourceFolderScanner，XmlScanner，GradleScanner，BinaryResourceScanner，OtherFileScanner`，后面我们会详细介绍其中的`JavaPsiScanner`。有意思的是，这些Scanner接口中定义的所有方法都在Detector类中都对应有相同签名的方法，也就是`Detector`是所有的`Scanner`的适配器，所以检查器一般会继承`Detector`类并实现某个`Scanner`接口。下面是`XmlScanner`和`GradleScanner`两个接口的定义。

```java
/** Specialized interface for detectors that scan XML files */
public interface XmlScanner {
    /**
     * Visit the given document. The detector is responsible for its own iteration
     * through the document.
     * @param context information about the document being analyzed
     * @param document the document to examine
     */
    void visitDocument(@NonNull XmlContext context, @NonNull Document document);

    /**
     * Visit the given element.
     * @param context information about the document being analyzed
     * @param element the element to examine
     */
    void visitElement(@NonNull XmlContext context, @NonNull Element element);

    /**
     * Visit the given element after its children have been analyzed.
     * @param context information about the document being analyzed
     * @param element the element to examine
     */
    void visitElementAfter(@NonNull XmlContext context, @NonNull Element element);

    /**
     * Visit the given attribute.
     * @param context information about the document being analyzed
     * @param attribute the attribute node to examine
     */
    void visitAttribute(@NonNull XmlContext context, @NonNull Attr attribute);

    /**
     * Returns the list of elements that this detector wants to analyze. If non
     * null, this detector will be called (specifically, the
     * {@link #visitElement} method) for each matching element in the document.
     * <p>
     * If this method returns null, and {@link #getApplicableAttributes()} also returns
     * null, then the {@link #visitDocument} method will be called instead.
     *
     * @return a collection of elements, or null, or the special
     *         {@link XmlScanner#ALL} marker to indicate that every single
     *         element should be analyzed.
     */
    @Nullable
    Collection<String> getApplicableElements();

    /**
     * Returns the list of attributes that this detector wants to analyze. If non
     * null, this detector will be called (specifically, the
     * {@link #visitAttribute} method) for each matching attribute in the document.
     * <p>
     * If this method returns null, and {@link #getApplicableElements()} also returns
     * null, then the {@link #visitDocument} method will be called instead.
     *
     * @return a collection of attributes, or null, or the special
     *         {@link XmlScanner#ALL} marker to indicate that every single
     *         attribute should be analyzed.
     */
    @Nullable
    Collection<String> getApplicableAttributes();

    /**
     * Special marker collection returned by {@link #getApplicableElements()} or
     * {@link #getApplicableAttributes()} to indicate that the check should be
     * invoked on all elements or all attributes
     */
    @NonNull
    List<String> ALL = new ArrayList<String>(0); // NOT Collections.EMPTY!
    // We want to distinguish this from just an *empty* list returned by the caller!
}

/** Specialized interface for detectors that scan Gradle files */
public interface GradleScanner {
    void visitBuildScript(@NonNull Context context, Map<String, Object> sharedData);
}
```

(4) `Issue`类表示应用中可能存在的问题，它一般关联着一个表示问题严重程度的`Severity`类，表示问题类别的`Category`类以及用来发现和检查这个问题的`Detector`(包含在`Implementation`类中)。  
**通俗来讲，Issue指的就是检查器去检查文件时发现它可能出现的问题。**

```java
/**
 * An issue is a potential bug in an Android application. An issue is discovered
 * by a {@link Detector}, and has an associated {@link Severity}.
 * <p>
 * Issues and detectors are separate classes because a detector can discover
 * multiple different issues as it's analyzing code, and we want to be able to
 * different severities for different issues, the ability to suppress one but
 * not other issues from the same detector, and so on.
 * <p>
 * <b>NOTE: This is not a public or final API; if you rely on this be prepared
 * to adjust your code for the next tools release.</b>
 */
public final class Issue implements Comparable<Issue> {
    private final String mId;//问题id，名称标识
    private final String mBriefDescription;//简单描述
    private final String mExplanation;//详细解释
    private final Category mCategory;//问题类别
    private final int mPriority;//问题等级
    private final Severity mSeverity;//问题严重程度
    private Object mMoreInfoUrls;//问题的更多信息，可能是一个网址的url
    private boolean mEnabledByDefault = true;//是否默认开启
    private Implementation mImplementation;//这个问题的检查器相关信息
    ...
}
```

(4.1) `Severity`类是表示问题严重程度的枚举类，主要分为了`FATAL，ERROR，WARNING，INFORMATIONAL，IGNORE`这几种程度。  

```java
/**
 * Severity of an issue found by lint
 * <p>
 * <b>NOTE: This is not a public or final API; if you rely on this be prepared
 * to adjust your code for the next tools release.</b>
 */
@Beta
public enum Severity {
    /**
     * Fatal: Use sparingly because a warning marked as fatal will be
     * considered critical and will abort Export APK etc in ADT
     */
    @NonNull
    FATAL("Fatal"),//标记为Fatal将被视为非常危险，在导出apk时可能会终止

    /**
     * Errors: The issue is known to be a real error that must be addressed.
     */
    @NonNull
    ERROR("Error"),//的确是一个问题

    /**
     * Warning: Probably a problem.
     */
    @NonNull
    WARNING("Warning"),//警告，可能是一个问题

    /**
     * Information only: Might not be a problem, but the check has found
     * something interesting to say about the code.
     */
    @NonNull
    INFORMATIONAL("Information"),//可能不是一个问题

    /**
     * Ignore: The user doesn't want to see this issue
     */
    @NonNull
    IGNORE("Ignore");//用户不想看到的问题
    ...
}
```

(4.2) `Category`类表示问题的类别，主要有`Correctness，Security，Performance，Usability，Accessibility，Internationalization`等，类别下面可以有子类别，每个类别都还有一个优先级。

```java
/**
 * A category is a container for related issues.
 * <p>
 * <b>NOTE: This is not a public or final API; if you rely on this be prepared
 * to adjust your code for the next tools release.</b>
 */
public final class Category implements Comparable<Category> {
    private final String mName;//类别名称
    private final int mPriority;//优先级
    private final Category mParent;//父类别
    ...
}
```

(4.3) `Implementation`类表示问题对应的检查器实现，除了绑定一个检查器之外，还绑定了相应的检查范围Scope。需要注意的是`mScope`和`mAnalysisScopes`的含义是不同的，表示的具体范围也不一定是一样的，有些问题比较复杂，可能需要分析更多的文件范围才能确定是否存在这个问题。例如，检查某个资源是否使用了，不仅需要检查资源XML文件，还要检查Java文件，只有这两个范围都没有使用这个资源才能确定地认为这个资源没有被使用。

```java
/**
 * An {@linkplain Implementation} of an {@link Issue} maps to the {@link Detector}
 * class responsible for analyzing the issue, as well as the {@link Scope} required
 * by the detector to perform its analysis.
 * <p>
 * <b>NOTE: This is not a public or final API; if you rely on this be prepared
 * to adjust your code for the next tools release.</b>
 */
@Beta
public class Implementation {
    private final Class<? extends Detector> mClass;//问题对应的检查器
    private final EnumSet<Scope> mScope;//检查器的检查范围，可能是存在很多的scope中
    private EnumSet<Scope>[] mAnalysisScopes;//检查器分析问题时的范围
    ...
}
```

未完待续...
