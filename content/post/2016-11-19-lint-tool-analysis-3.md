---
date: 2016-11-19T10:46:33+08:00
title: Lint Tool Analysis (3)
tags: ["android"]
---
Lint工具的源码分析(3)  <!--more-->

**本系列的几篇源码分析文档意义不大，如果你正好也在研究lint源码，或者你想知道前面自定义lint规则中提出的那几个问题，抑或你只是想大致了解下lint的源码都有些什么内容的话，这些文章可能有还些作用，否则看了和没看差不多的，因为这几篇文章只是我在读源码的过程中记录下来的一些零碎的片段，方便以后看的时候能够迅速上手。**

前面我们提了很多lint工具中`detector.api`和`client.api`包下的类，但是还没介绍到lint检查器到底是如何对文件进行检查的，这也就是本节需要介绍的知识点。

### 3. Lint检查器的前提知识

首先我们需要了解的是，lint工具在实现lint检查时使用了Visitor设计模式，推荐阅读[这篇文章](http://en.wikipedia.org/wiki/Visitor_pattern)看下一般如何来实现这个设计模式。我们每个lint检查器在使用之前都要进行注册，注册的时候它也指明了它的工作范围以及它感兴趣的文件、方法甚至语句等。当lint工具开始扫描项目文件进行lint检查时，如果发现某个检查器感兴趣的内容就会交给对应的检查器去做相应的检查，如果有错就会报出错误，如果没有就表示代码通过检查，这就是一种visitor模式的体现。

其次我们需要知道的是关于Java代码的解析，一般来说，对代码的解析都是将其转换成抽象语法树，英文名是Abstract Syntax Tree，它是开发工具中很多功能的内部实现原理，例如删除无用的声明语句，变量重命名等。推荐阅读[Abstract Syntax Tree](http://www.eclipse.org/articles/Article-JavaCodeManipulation_AST/)这篇文章来了解AST，其中也介绍到了Visitor设计模式，并简单道出了lint检查的核心原理。

最后，关于lint工具的实现还有不少有意思的槽点，下面的几段英文内容摘录自[google code上关于lint工具的一个讨论](http://code.google.com/p/android/issues/detail?id=224584)，其中lint开发者解释了他们在实现Java文件解析时的技术方案选型原因、目前存在的问题以及将来的开发方向。

In 2.2, I've completely rewritten the Java handling in lint. This was necessary in order to support Java 8 (which Nougat now supports). To do this, I replaced the Lombok AST stuff (which didn't even properly support Java 7) with "PSI" (which are the same APIs as IntelliJ is using internally, except in lint's case, it's backed by a bridge to ECJ). This has a bunch of advantages: the PSI API is much cleaner, it contains type resolution right built in (instead of the ugly parallel ResolvedNode hierarchy I built up to augment Lombok which didn't support type resolution). So for example, when you're handed a method call node, you can call .resolve() on it and it will return the method the call invokes etc etc.

**[大致内容]** 在Android Studio 2.2版本中，为了支持Java 8(Android Nougat支持Java 8)，开发者完全重写了lint工具中对Java代码的解析。以前使用的是`Lombok AST`(连Java 7都不支持)，现在使用的是`PSI`(和Intellij内部对Java代码解析使用的是同一套API，但是lint除外，它使用的是`ECJ [Eclipse Compiler for Java]`)。   
PSI API有很多好处，它更加简洁，并且内置了类型解析功能(Lombok不知道类型解析)。所以，开发者将原有的lint检查项基本上全部使用PSI API重写了一遍，下面是重写的[提交记录](https://android.googlesource.com/platform/tools/base/+/8cdccd1bdf595b9b5e9a040a380d5a3372807fb2)。

However, I didn't actually delete the old Lombok code path, since some people my have custom rules using Lombok. So, if lint comes across a project that is using custom lint rules, it has to process the file TWICE: first using the PSI bridge, and then all over again with Lombok. This obviously slows downs things.

**[大致内容]** 但是，考虑到还是有人会使用Lombok API来开发自定义的lint规则，所以开发者并没有删除旧的Lombok相关代码。这也导致如果项目中使用了旧的API自定义的lint规则的话，lint会对这个文件检查两次，从而使得lint检查的速度变慢。

I have a commented out warning in the lint driver which emits a warning when this is the case (basically explaining that lint came across a custom lint rule which is using the old APIs, which still works, but slows things down and may not work in the future.)

However, I disabled that because I may still do another big change to the APIs -- and I don't want to force everyone to jump through hoops of porting their lint checks to the new 2.2 APIs, only to have them change them again shortly.

The API change I'm referring to is UAST; a "universal AST" that JetBrains is working on. It's pretty similar to PSI (so certainly porting to the current PSI apis will make a much smaller migration to UAST than straight from Lombok), but the idea is that it's a bit more language agnostic, so for example a single lint AST check can work not just with Java but also transparently with Kotlin, etc.

**[大致内容]** 虽然开发者目前已经将Lombok API升级到PSI API，但是他们正在计划着做另一个重大的变化，也就是升级到`UAST` API，这个是JetBrains目前正在做的。它和PSI API类似，但是思想上更加先进，更加与语言无关，例如一个简单的lint检查可能不止可以作用在Java代码上，也能作用在Kotlin代码上。

假设现在我们想要将原来的Lombok API形式的lint检查升级到PSI API形式，我们该如何做呢？   
详情可以参考`JavaPsiScanner`类的注释内容，其中详细介绍了如何将API轻松迁移，但是轻松只是相对于那些熟悉PSI API的开发者，对于不熟悉它的开发者来说，这种迁移还是比较困难的。当我们自定义lint检查器的时候需要注意 **lint-api的版本问题**，不同版本的Java检查器需要实现的接口有差异。   
(1) `compile 'com.android.tools.lint:lint-api:24.5.0'`   
使用`JavaScanner` => older Lombok AST API   
(2) `compile 'com.android.tools.lint:lint-api:25.2.0'`   
需要迁移到`JavaPsiScanner` => IntelliJ IDEA's "PSI" API

### 4. Java代码的Lint检查器

(1) `JavaParser`   
解析Java文件的抽象类，实际实现类是`LombokPsiParser`，将来可能会被修改为其他的Parser。

(2) `JavaPsiScanner`   
**注意：在最新的25.2.0版本的lint-api中JavaScanner已经被注明为deprecated了，推荐使用JavaPsiScanner。**   
下面是`JavaPsiScanner`接口的源码，任何对Java源代码文件进行lint检查的Detector都需要实现这个接口，主要是定义了几个`visit`方法。

```java
public interface JavaPsiScanner  {
    /**
     * Create a parse tree visitor to process the parse tree. All
     * {@link JavaScanner} detectors must provide a visitor, unless they
     * either return true from {@link #appliesToResourceRefs()} or return
     * non null from {@link #getApplicableMethodNames()}.
     * <p>
     * If you return specific AST node types from
     * {@link #getApplicablePsiTypes()}, then the visitor will <b>only</b>
     * be called for the specific requested node types. This is more
     * efficient, since it allows many detectors that apply to only a small
     * part of the AST (such as method call nodes) to share iteration of the
     * majority of the parse tree.
     * <p>
     * If you return null from {@link #getApplicablePsiTypes()}, then your
     * visitor will be called from the top and all node types visited.
     * <p>
     * Note that a new visitor is created for each separate compilation
     * unit, so you can store per file state in the visitor.
     * <p>
     * <b>
     * NOTE: Your visitor should <b>NOT</b> extend JavaRecursiveElementVisitor.
     * Your visitor should only visit the current node type; the infrastructure
     * will do the recursion. (Lint's unit test infrastructure will check and
     * enforce this restriction.)
     * </b>
     *
     * @param context the {@link Context} for the file being analyzed
     * @return a visitor, or null.
     */
    @Nullable
    JavaElementVisitor createPsiVisitor(@NonNull JavaContext context);

    /**
     * Return the types of AST nodes that the visitor returned from
     * {@link #createJavaVisitor(JavaContext)} should visit. See the
     * documentation for {@link #createJavaVisitor(JavaContext)} for details
     * on how the shared visitor is used.
     * <p>
     * If you return null from this method, then the visitor will process
     * the full tree instead.
     * <p>
     * Note that for the shared visitor, the return codes from the visit
     * methods are ignored: returning true will <b>not</b> prune iteration
     * of the subtree, since there may be other node types interested in the
     * children. If you need to ensure that your visitor only processes a
     * part of the tree, use a full visitor instead. See the
     * OverdrawDetector implementation for an example of this.
     *
     * @return the list of applicable node types (AST node classes), or null
     */
    @Nullable
    List<Class<? extends PsiElement>> getApplicablePsiTypes();

    /**
     * Return the list of method names this detector is interested in, or
     * null. If this method returns non-null, then any AST nodes that match
     * a method call in the list will be passed to the
     * {@link #visitMethod(JavaContext, JavaElementVisitor, PsiMethodCallExpression, PsiMethod)}
     * method for processing. The visitor created by
     * {@link #createPsiVisitor(JavaContext)} is also passed to that
     * method, although it can be null.
     * <p>
     * This makes it easy to write detectors that focus on some fixed calls.
     * For example, the StringFormatDetector uses this mechanism to look for
     * "format" calls, and when found it looks around (using the AST's
     * {@link PsiElement#getParent()} method) to see if it's called on
     * a String class instance, and if so do its normal processing. Note
     * that since it doesn't need to do any other AST processing, that
     * detector does not actually supply a visitor.
     *
     * @return a set of applicable method names, or null.
     */
    @Nullable
    List<String> getApplicableMethodNames();

    /**
     * Method invoked for any method calls found that matches any names
     * returned by {@link #getApplicableMethodNames()}. This also passes
     * back the visitor that was created by
     * {@link #createJavaVisitor(JavaContext)}, but a visitor is not
     * required. It is intended for detectors that need to do additional AST
     * processing, but also want the convenience of not having to look for
     * method names on their own.
     *
     * @param context the context of the lint request
     * @param visitor the visitor created from
     *            {@link #createPsiVisitor(JavaContext)}, or null
     * @param call the {@link PsiMethodCallExpression} node for the invoked method
     * @param method the {@link PsiMethod} being called
     */
    void visitMethod(
            @NonNull JavaContext context,
            @Nullable JavaElementVisitor visitor,
            @NonNull PsiMethodCallExpression call,
            @NonNull PsiMethod method);

    /**
     * Return the list of constructor types this detector is interested in, or
     * null. If this method returns non-null, then any AST nodes that match
     * a constructor call in the list will be passed to the
     * {@link #visitConstructor(JavaContext, JavaElementVisitor, PsiNewExpression, PsiMethod)}
     * method for processing. The visitor created by
     * {@link #createJavaVisitor(JavaContext)} is also passed to that
     * method, although it can be null.
     * <p>
     * This makes it easy to write detectors that focus on some fixed constructors.
     *
     * @return a set of applicable fully qualified types, or null.
     */
    @Nullable
    List<String> getApplicableConstructorTypes();

    /**
     * Method invoked for any constructor calls found that matches any names
     * returned by {@link #getApplicableConstructorTypes()}. This also passes
     * back the visitor that was created by
     * {@link #createPsiVisitor(JavaContext)}, but a visitor is not
     * required. It is intended for detectors that need to do additional AST
     * processing, but also want the convenience of not having to look for
     * method names on their own.
     *
     * @param context the context of the lint request
     * @param visitor the visitor created from
     *            {@link #createPsiVisitor(JavaContext)}, or null
     * @param node the {@link PsiNewExpression} node for the invoked method
     * @param constructor the called constructor method
     */
    void visitConstructor(
            @NonNull JavaContext context,
            @Nullable JavaElementVisitor visitor,
            @NonNull PsiNewExpression node,
            @NonNull PsiMethod constructor);

    /**
     * Return the list of reference names types this detector is interested in, or null. If this
     * method returns non-null, then any AST elements that match a reference in the list will be
     * passed to the {@link #visitReference(JavaContext, JavaElementVisitor,
     * PsiJavaCodeReferenceElement, PsiElement)} method for processing. The visitor created by
     * {@link #createJavaVisitor(JavaContext)} is also passed to that method, although it can be
     * null. <p> This makes it easy to write detectors that focus on some fixed references.
     *
     * @return a set of applicable reference names, or null.
     */
    @Nullable
    List<String> getApplicableReferenceNames();

    /**
     * Method invoked for any references found that matches any names returned by {@link
     * #getApplicableReferenceNames()}. This also passes back the visitor that was created by
     * {@link #createPsiVisitor(JavaContext)}, but a visitor is not required. It is intended for
     * detectors that need to do additional AST processing, but also want the convenience of not
     * having to look for method names on their own.
     *
     * @param context    the context of the lint request
     * @param visitor    the visitor created from {@link #createPsiVisitor(JavaContext)}, or
     *                   null
     * @param reference  the {@link PsiJavaCodeReferenceElement} element
     * @param referenced the referenced element
     */
    void visitReference(
            @NonNull JavaContext context,
            @Nullable JavaElementVisitor visitor,
            @NonNull PsiJavaCodeReferenceElement reference,
            @NonNull PsiElement referenced);

    /**
     * Returns whether this detector cares about Android resource references
     * (such as {@code R.layout.main} or {@code R.string.app_name}). If it
     * does, then the visitor will look for these patterns, and if found, it
     * will invoke {@link #visitResourceReference} passing the resource type
     * and resource name. It also passes the visitor, if any, that was
     * created by {@link #createJavaVisitor(JavaContext)}, such that a
     * detector can do more than just look for resources.
     *
     * @return true if this detector wants to be notified of R resource
     *         identifiers found in the code.
     */
    boolean appliesToResourceRefs();

    /**
     * Called for any resource references (such as {@code R.layout.main}
     * found in Java code, provided this detector returned {@code true} from
     * {@link #appliesToResourceRefs()}.
     *
     * @param context the lint scanning context
     * @param visitor the visitor created from
     *            {@link #createPsiVisitor(JavaContext)}, or null
     * @param node the variable reference for the resource
     * @param type the resource type, such as "layout" or "string"
     * @param name the resource name, such as "main" from
     *            {@code R.layout.main}
     * @param isFramework whether the resource is a framework resource
     *            (android.R) or a local project resource (R)
     */
    void visitResourceReference(
            @NonNull JavaContext context,
            @Nullable JavaElementVisitor visitor,
            @NonNull PsiElement node,
            @NonNull ResourceType type,
            @NonNull String name,
            boolean isFramework);

    /**
     * Returns a list of fully qualified names for super classes that this
     * detector cares about. If not null, this detector will <b>only</b> be called
     * if the current class is a subclass of one of the specified superclasses.
     *
     * @return a list of fully qualified names
     */
    @Nullable
    List<String> applicableSuperClasses();

    /**
     * Called for each class that extends one of the super classes specified with
     * {@link #applicableSuperClasses()}.
     * <p>
     * Note: This method will not be called for {@link PsiTypeParameter} classes. These
     * aren't really classes in the sense most lint detectors think of them, so these
     * are excluded to avoid having lint checks that don't defensively code for these
     * accidentally report errors on type parameters. If you really need to check these,
     * use {@link #getApplicablePsiTypes} with {@code PsiTypeParameter.class} instead.
     *
     * @param context the lint scanning context
     * @param declaration the class declaration node, or null for anonymous classes
     */
    void checkClass(@NonNull JavaContext context, @NonNull PsiClass declaration);
}
```

(3) 下面以`LogDetector`为例，介绍下一个Java代码的Lint检查器的大致结构：   
① 首先声明`LogDetector`继承自`Detector`并实现了`JavaPsiScanner`接口，`Detector`类是检查器的适配器类，`JavaPsiScanner`接口是对Java代码文件进行检查的接口；  
② 接着定义一个`Implementation`实例，声明这个检查器的实现类是`LogDetector.class`，它的检查范围是`Scope.JAVA_FILE_SCOPE`，也就是Java代码文件；  
③ 然后定义这个检查器将会检查代码中是否存在的`Issue`，每个问题有名称(`LogConditional`)、描述、类别(`Category.PERFORMANCE`)、等级(`5`)、严重程度(`Severity.WARNING`)、检查器的实现类以及是否默认开启等信息；  
④ 接着在方法`getApplicableMethodNames`中声明这个检查器关心的方法，因为这个检查器是检查应用中的log是否符合规范，所以比较关心`d/e/i/v/w`等常见的log打印方法；  
⑤ 最后就是在方法`visitMethod`中对上面声明的并且在lint检查时遇到的那些方法进行检查，看它们是否符合规范，如果不符合规范的话就会report出错误信息。源代码文件中声明其他的变量和私有方法都是为了完成检查过程定义的。  

```java
/**
 * Detector for finding inefficiencies and errors in logging calls.
 */
public class LogDetector extends Detector implements JavaPsiScanner {
    private static final Implementation IMPLEMENTATION = new Implementation(
          LogDetector.class, Scope.JAVA_FILE_SCOPE);

    /** Log call missing surrounding if */
    public static final Issue CONDITIONAL = Issue.create(
            "LogConditional", //$NON-NLS-1$
            "Unconditional Logging Calls",
            "The BuildConfig class (available in Tools 17) provides a constant, \"DEBUG\", " +
            "which indicates whether the code is being built in release mode or in debug " +
            "mode. In release mode, you typically want to strip out all the logging calls. " +
            "Since the compiler will automatically remove all code which is inside a " +
            "\"if (false)\" check, surrounding your logging calls with a check for " +
            "BuildConfig.DEBUG is a good idea.\n" +
            "\n" +
            "If you *really* intend for the logging to be present in release mode, you can " +
            "suppress this warning with a @SuppressLint annotation for the intentional " +
            "logging calls.",

            Category.PERFORMANCE,
            5,
            Severity.WARNING,
            IMPLEMENTATION).setEnabledByDefault(false);

    /** Mismatched tags between isLogging and log calls within it */
    public static final Issue WRONG_TAG = Issue.create(
            "LogTagMismatch", //$NON-NLS-1$
            "Mismatched Log Tags",
            "When guarding a `Log.v(tag, ...)` call with `Log.isLoggable(tag)`, the " +
            "tag passed to both calls should be the same. Similarly, the level passed " +
            "in to `Log.isLoggable` should typically match the type of `Log` call, e.g. " +
            "if checking level `Log.DEBUG`, the corresponding `Log` call should be `Log.d`, " +
            "not `Log.i`.",

            Category.CORRECTNESS,
            5,
            Severity.ERROR,
            IMPLEMENTATION);

    /** Log tag is too long */
    public static final Issue LONG_TAG = Issue.create(
            "LongLogTag", //$NON-NLS-1$
            "Too Long Log Tags",
            "Log tags are only allowed to be at most 23 tag characters long.",

            Category.CORRECTNESS,
            5,
            Severity.ERROR,
            IMPLEMENTATION);

    @SuppressWarnings("SpellCheckingInspection")
    private static final String IS_LOGGABLE = "isLoggable";       //$NON-NLS-1$
    public static final String LOG_CLS = "android.util.Log";     //$NON-NLS-1$
    private static final String PRINTLN = "println";              //$NON-NLS-1$

    // ---- Implements Detector.JavaScanner ----

    @Override
    public List<String> getApplicableMethodNames() {
        return Arrays.asList(
                "d",           //$NON-NLS-1$
                "e",           //$NON-NLS-1$
                "i",           //$NON-NLS-1$
                "v",           //$NON-NLS-1$
                "w",           //$NON-NLS-1$
                PRINTLN,
                IS_LOGGABLE);
    }

    @Override
    public void visitMethod(@NonNull JavaContext context, @Nullable JavaElementVisitor visitor,
            @NonNull PsiMethodCallExpression node, @NonNull PsiMethod method) {
        JavaEvaluator evaluator = context.getEvaluator();
        if (!evaluator.isMemberInClass(method, LOG_CLS)) {
            return;
        }

        String name = method.getName();
        boolean withinConditional = IS_LOGGABLE.equals(name) ||
                checkWithinConditional(context, node.getParent(), node);

        // See if it's surrounded by an if statement (and it's one of the non-error, spammy
        // log methods (info, verbose, etc))
        if (("i".equals(name) || "d".equals(name) || "v".equals(name) || PRINTLN.equals(name))
                && !withinConditional
                && performsWork(context, node)
                && context.isEnabled(CONDITIONAL)) {
            String message = String.format("The log call Log.%1$s(...) should be " +
                            "conditional: surround with `if (Log.isLoggable(...))` or " +
                            "`if (BuildConfig.DEBUG) { ... }`",
                    node.getMethodExpression().getReferenceName());
            context.report(CONDITIONAL, node, context.getLocation(node), message);
        }

        // Check tag length
        if (context.isEnabled(LONG_TAG)) {
            int tagArgumentIndex = PRINTLN.equals(name) ? 1 : 0;
            PsiParameterList parameterList = method.getParameterList();
            PsiExpressionList argumentList = node.getArgumentList();
            if (evaluator.parameterHasType(method, tagArgumentIndex, TYPE_STRING)
                    && parameterList.getParametersCount() == argumentList.getExpressions().length) {
                PsiExpression argument = argumentList.getExpressions()[tagArgumentIndex];
                String tag = ConstantEvaluator.evaluateString(context, argument, true);
                if (tag != null && tag.length() > 23) {
                    String message = String.format(
                            "The logging tag can be at most 23 characters, was %1$d (%2$s)",
                            tag.length(), tag);
                    context.report(LONG_TAG, node, context.getLocation(node), message);
                }
            }
        }
    }

    /** Returns true if the given logging call performs "work" to compute the message */
    private static boolean performsWork(
            @NonNull JavaContext context,
            @NonNull PsiMethodCallExpression node) {
        //...
    }

    private static boolean checkWithinConditional(
            @NonNull JavaContext context, @Nullable PsiElement curr, @NonNull PsiMethodCallExpression logCall) {
        //...
    }

    /** Checks that the tag passed to Log.s and Log.isLoggable match */
    private static void checkTagConsistent(JavaContext context, PsiMethodCallExpression logCall,
            PsiMethodCallExpression isLoggableCall) {
        //...
    }
}
```

上面是一个简单的Java检查器的实现，但是足以让我们理解lint检查是如何进行的，以及辅助我们去了解其他的检查器的实现，甚至是针对其他类型的文件比如XML文件的检查器，它们的实现过程也大致类似。那如果我们的检查器既需要检查Java文件，又需要检查XML文件怎么办呢？其实也就是多实现一个接口就行了，很多自带的检查器都是实现了`XmlScanner`和`JavaPsiScanner`两个接口的。

下一节我们会总结下lint工具中自带的一些和Android有关的检查器的功能。
