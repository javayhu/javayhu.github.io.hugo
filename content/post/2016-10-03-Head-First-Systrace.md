---
title: Head First Systrace
categories: "android"
date: "2016-10-03"
---
深入浅出systrace（1）systrace的简单介绍和systrace工具源码分析。 <!--more-->

**1.systrace工具简单介绍**

英文介绍文档推荐阅读官方文档[systrace-commandline](https://developer.android.com/studio/profile/systrace-commandline.html)

The Systrace tool helps analyze the performance of your application by capturing and displaying execution times of your applications processes and other Android system processes. The tool combines data from the Android kernel such as the CPU scheduler, disk activity, and application threads to generate an HTML report that shows an overall picture of an Android device’s system processes for a given period of time.

中文介绍文档推荐看[这篇文章](http://www.ithtw.com/1009.html)，从中我们可以知道

systrace是`Android4.1(API 16)`中新增的性能数据采样和分析工具，它可帮助开发者收集Android关键子系统（如surfaceflinger、WindowManagerService等Framework部分关键模块、服务，View系统等）的运行信息，从而帮助开发者更直观的分析系统瓶颈，改进性能。systrace的功能包括跟踪系统的I/O操作、内核工作队列、CPU负载以及Android各个子系统的运行状况等。在Android平台中，它主要由3部分组成：

**内核部分**：systrace利用了Linux Kernel中的`ftrace`功能，所以，如果要使用systrace的话，必须开启kernel中和ftrace相关的模块。
**数据采集部分**：Android定义了一个Trace类，应用程序可利用该类把统计信息输出给ftrace。同时，Android还有一个`atrace`程序，它可以从ftrace中读取统计信息然后交给数据分析工具来处理。
**数据分析工具**：Android SDK中提供一个systrace.py脚本用来配置数据采集的方式（如采集数据的标签、输出文件名等）和收集ftrace统计数据并生成一个结果网页文件供用户查看。

**从本质上说，systrace是对Linux Kernel中ftrace的封装，应用进程需要利用Android提供的Trace类来使用systrace。**

**2.systrace数据抓取方式**

除了使用Android Studio和Eclipse中集成的systrace工具之外，我们还可以使用Android SDK中提供的systrace工具来抓取性能日志。systrace.py是个脚本文件，位于`{Android SDK}/platform-tools/systrace`文件夹中，它的作用是收集systrace数据并提供网页文件结果供用户查看。

需要注意的是，不同版本的Android系统对应的systrace命令的参数形式略有不同，下面是常用的调用形式

```
python systrace.py [options] [category1] [category2] ... [categoryN]
```

下面是Android 4.3及以上版本的Android系统的systrace命令参数形式。
![img](/images/systrace_options_43.png)

下面是Android 4.2及以下版本的Android系统的systrace命令参数形式。

![img](/images/systrace_options_41.png)

systrace工具实际上是调用atrace命令来获取数据结果，所以其实也可以执行atrace命令来抓取数据。

```
➜  ~ adb shell atrace -h
atrace: invalid option -- h

usage: atrace [options] [categories...]
options include:
  -a appname      enable app-level tracing for a comma separated list of cmdlines
  -b N            use a trace buffer size of N KB
  -c              trace into a circular buffer
  -k fname,...    trace the listed kernel functions
  -n              ignore signals
  -s N            sleep for N seconds before tracing [default 0]
  -t N            trace for N seconds [defualt 5]
  -z              compress the trace dump
  --async_start   start circular trace and return immediatly
  --async_dump    dump the current contents of circular trace buffer
  --async_stop    stop tracing and dump the current contents of circular
                    trace buffer
  --list_categories
                  list the available tracing categories
```

**3.systrace工具源码分析**

**3.1 systrace工具的源码目录结构**

```
➜  systrace tree
.
├── AUTHORS
├── LICENSE
├── NOTICE
├── UPSTREAM_REVISION
├── agents
│   ├── __init__.py
│   └── atrace_agent.py
├── prefix.html
├── suffix.html
├── systrace-legacy.py
├── systrace.py
├── systrace_agent.py
├── systrace_trace_viewer.html
├── trace.html
└── util.py

1 directory, 14 files
```

systrace工具中的主要类和类中的方法及其之间的关系如下图所示：

![img](/images/systrace.png)

**3.2 systrace.py文件**

**3.2.1 python版本问题**

从systrace.py的脚本内容来看，systrace工具只支持Python 2.7版本，不支持其他的python版本。

```python
# Make sure we're using a new enough version of Python.
# The flags= parameter of re.sub() is new in Python 2.7. And Systrace does not
# support Python 3 yet.
version = sys.version_info[:2]
if version != (2, 7):
  sys.stderr.write('This script does not support Python %d.%d. '
                   'Please use Python 2.7.\n' % version)
  sys.exit(1)
```

**3.2.2 systrace.py文件分析**

从main方法中可以看出抓取systrace的主流程是：
1.解析命令行中的参数，对应parse_options方法；
2.根据参数创建对应的agent，对应create_agents方法；
3.启动agent来抓取性能日志，对应agent的start方法；
4.收集agent抓取得到的性能日志，对应agent的collect_result方法；
5.将收集的数据写入到html文件中，对应write_trace_html方法。

```python
def main():
  options, categories = parse_options(sys.argv)
  agents = create_agents(options, categories)

  if not agents:
    dirs = DEFAULT_AGENT_DIR
    if options.agent_dirs:
      dirs += ',' + options.agent_dirs
    sys.stderr.write('No systrace agent is available in directories |%s|.\n' %
                     dirs)
    sys.exit(1)

  try:
    update_systrace_trace_viewer = __import__('update_systrace_trace_viewer')
  except ImportError:
    pass
  else:
    update_systrace_trace_viewer.update()

  for a in agents:
    a.start()

  for a in agents:
    a.collect_result()
    if not a.expect_trace():
      # Nothing more to do.
      return

  script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
  write_trace_html(options.output_file, script_dir, agents)
```

1.parse_options方法使用的是`optparse`模块来初始化命令参数和解析命令行。

```python
def parse_options(argv):
  """Parses and checks the command-line options.

  Returns:
    A tuple containing the options structure and a list of categories to
    be traced.
  """
  usage = 'Usage: %prog [options] [category1 [category2 ...]]'
  desc = 'Example: %prog -b 32768 -t 15 gfx input view sched freq'
  parser = optparse.OptionParser(usage=usage, description=desc)
  parser.add_option('-o', dest='output_file', help='write HTML to FILE',
                    default='trace.html', metavar='FILE')
  parser.add_option('-t', '--time', dest='trace_time', type='int',
                    help='trace for N seconds', metavar='N')
  parser.add_option('-b', '--buf-size', dest='trace_buf_size', type='int',
                    help='use a trace buffer size of N KB', metavar='N')
  ...... more options ......
  options, categories = parser.parse_args(argv[1:])

  if options.link_assets or options.asset_dir != 'trace-viewer':
    parser.error('--link-assets and --asset-dir are deprecated.')

  if (options.trace_time is not None) and (options.trace_time <= 0):
    parser.error('the trace time must be a positive number')

  if (options.trace_buf_size is not None) and (options.trace_buf_size <= 0):
    parser.error('the trace buffer size must be a positive number')

  return (options, categories)
```

2.create_agents方法根据解析的命令行参数创建并初始化agents，所谓的agent就是一个用来获取systrace数据的本地代理。使用者可以通过`--agent-dirs`来指定agent存放的目录，如果没有指定的话会默认加载并创建放在agents这个目录(package)下面的agents。其中的`try_create_agent`方法的实现在`atrace_agent.py`文件中，后面会介绍到。

```python
def create_agents(options, categories):
  """Create systrace agents.

  This function will search systrace agent modules in agent directories and
  create the corresponding systrace agents.
  Args:
    options: The command-line options.
categories: "The"
  Returns:
    The list of systrace agents.
  """
  agent_dirs = [os.path.join(os.path.dirname(__file__), DEFAULT_AGENT_DIR)]
  if options.agent_dirs:
    agent_dirs.extend(options.agent_dirs.split(','))

  agents = []
  for agent_dir in agent_dirs:
    if not agent_dir:
      continue
    for filename in os.listdir(agent_dir):
      (module_name, ext) = os.path.splitext(filename)
      if (ext != '.py' or module_name == '__init__'
          or module_name.endswith('_unittest')):
        continue
      (f, pathname, data) = imp.find_module(module_name, [agent_dir])
      try:
        module = imp.load_module(module_name, f, pathname, data)
      finally:
        if f:
          f.close()
      if module:
        agent = module.try_create_agent(options, categories)
        if not agent:
          continue
        agents.append(agent)
  return agents
```

3.write_trace_html方法用来将agents收集的数据写入到html文件中，通常我们得到的网页结果文件的开头和结尾都是一样的，因为这个方法生成html文件的方式是先写入`prefix.html`文件，然后遍历agents得到的结果并写入，最后写入`suffix.html`文件。

```python
def write_trace_html(html_filename, script_dir, agents):
  """Writes out a trace html file.

  Args:
    html_filename: The name of the file to write.
    script_dir: The directory containing this script.
    agents: The systrace agents.
  """
  systrace_dir = os.path.abspath(os.path.dirname(__file__))
  html_prefix = read_asset(systrace_dir, 'prefix.html')
  html_suffix = read_asset(systrace_dir, 'suffix.html')
  trace_viewer_html = read_asset(script_dir, 'systrace_trace_viewer.html')

  # Open the file in binary mode to prevent python from changing the
  # line endings.
  html_file = open(html_filename, 'wb')
  html_file.write(html_prefix.replace('{{SYSTRACE_TRACE_VIEWER_HTML}}',
                                      trace_viewer_html))

  html_file.write('<!-- BEGIN TRACE -->\n')
  for a in agents:
    html_file.write('  <script class="')
    html_file.write(a.get_class_name())
    html_file.write('" type="application/text">\n')
    html_file.write(a.get_trace_data())
    html_file.write('  </script>\n')
  html_file.write('<!-- END TRACE -->\n')

  html_file.write(html_suffix)
  html_file.close()
  print('\n    wrote file://%s\n' % os.path.abspath(html_filename))
```

**3.3 util.py文件**

util.py从文件名字可知它是一个工具类，里面主要是定义了执行adb命令的方法`run_adb_shell`和通过这个方法获取设备的sdk版本的方法`get_device_sdk_version`。

**3.3.1 run_adb_shell方法**

该方法将传入的shell命令以及设备的序列号构建成`adb -s serial shell xxx`的形式，然后利用`subprocess`模块执行命令并获取得到输出的结果。

```python
def run_adb_shell(shell_args, device_serial):
  """Runs "adb shell" with the given arguments.

  Args:
    shell_args: array of arguments to pass to adb shell.
    device_serial: if not empty, will add the appropriate command-line
        parameters so that adb targets the given device.
  Returns:
    A tuple containing the adb output (stdout & stderr) and the return code
    from adb.  Will exit if adb fails to start.
  """
  adb_command = construct_adb_shell_command(shell_args, device_serial)

  adb_output = []
  adb_return_code = 0
  try:
    adb_output = subprocess.check_output(adb_command, stderr=subprocess.STDOUT,
                                         shell=False, universal_newlines=True)
  except OSError as error:
    # This usually means that the adb executable was not found in the path.
    print >> sys.stderr, ('\nThe command "%s" failed with the following error:'
                          % ' '.join(adb_command))
    print >> sys.stderr, '    %s' % str(error)
    print >> sys.stderr, 'Is adb in your path?'
    adb_return_code = error.errno
    adb_output = error
  except subprocess.CalledProcessError as error:
    # The process exited with an error.
    adb_return_code = error.returncode
    adb_output = error.output

  return (adb_output, adb_return_code)
```

**3.3.2 get_device_sdk_version方法**

该方法用来获取设备的sdk版本号，它先是利用OptionParser来解析出命令行中的设备序列号，然后调用run_adb_shell方法通过命令来获取sdk版本号。这个方法在`atrace_agent`的`try_create_agent`方法中被调用，因为对于不同版本号的Android系统其systrace命令的参数形式略有不同，导致处理方式也略有不同。

```python
def get_device_sdk_version():
  """Uses adb to attempt to determine the SDK version of a running device."""

  getprop_args = ['getprop', 'ro.build.version.sdk']

  # get_device_sdk_version() is called before we even parse our command-line
  # args.  Therefore, parse just the device serial number part of the
  # command-line so we can send the adb command to the correct device.
  parser = OptionParserIgnoreErrors()
  parser.add_option('-e', '--serial', dest='device_serial', type='string')
  options, unused_args = parser.parse_args() # pylint: disable=unused-variable

  success = False

  adb_output, adb_return_code = run_adb_shell(getprop_args,
                                              options.device_serial)

  if adb_return_code == 0:
    # ADB may print output other than the version number (e.g. it chould
    # print a message about starting the ADB server).
    # Break the ADB output into white-space delimited segments.
    parsed_output = str.split(adb_output)
    if parsed_output:
      # Assume that the version number is the last thing printed by ADB.
      version_string = parsed_output[-1]
      if version_string:
        try:
          # Try to convert the text into an integer.
          version = int(version_string)
        except ValueError:
          version = -1
        else:
          success = True

  if not success:
    print >> sys.stderr, (
        '\nThe command "%s" failed with the following message:'
        % ' '.join(getprop_args))
    print >> sys.stderr, adb_output
    sys.exit(1)

  return version
```

**3.4 systrace_agent.py文件**

systrace_agent.py文件中定义了`SystraceAgent`类，其中定义了agent的各个抽象方法，例如启动agent的`start`方法、收集systrace数据的`collect_result`方法以及获取systrace数据的`get_trace_data`方法等。

```python
class SystraceAgent(object):
  """The base class for systrace agents.

  A systrace agent contains the command-line options and trace categories to
  capture. Each systrace agent has its own tracing implementation.
  """

  def __init__(self, options, categories):
    """Initialize a systrace agent.

    Args:
      options: The command-line options.
categories: "The"
    """
    self._options = options
    self._categories = categories

  def start(self):
    """Start tracing.
    """
    raise NotImplementedError()

  def collect_result(self):
    """Collect the result of tracing.

    This function will block while collecting the result. For sync mode, it
    reads the data, e.g., from stdout, until it finishes. For async mode, it
    blocks until the agent is stopped and the data is ready.
    """
    raise NotImplementedError()

  def expect_trace(self):
    """Check if the agent is returning a trace or not.

    This will be determined in collect_result().
    Returns:
      Whether the agent is expecting a trace or not.
    """
    raise NotImplementedError()

  def get_trace_data(self):
    """Get the trace data.

    Returns:
      The trace data.
    """
    raise NotImplementedError()

  def get_class_name(self):
    """Get the class name

    The class name is used to identify the trace type when the trace is written
    to the html file
    Returns:
      The class name.
    """
    raise NotImplementedError()
```

**3.5 atrace_agent.py文件**

**3.5.1 三个Agent类和一些Category**

该文件定义了三个agent类，首先是`AtraceAgent`类，继承自`SystraceAgent`，是一个核心agent；然后是`AtraceLegacyAgent`，继承自`AtraceAgent`，主要是为了兼容Android 4.1及以下版本的系统；最后是`BootAgent`，继承自`AtraceAgent`，主要是为了实现在系统启动时的systrace数据抓取。

在命令执行的时候具体创建哪个agent是由方法`try_create_agent`方法来决定的，该方法会先获取设备的sdk版本。如果版本号大于等于18(Android 4.3及以上版本)，再看参数中是否包含了`--boot`选项，如果包含了的话就创建BootAgent，如果没有包含的话就创建AtraceAgent；如果版本号大于等于16且小于18(Android 4.1和Android 4.2版本)，就创建AtraceLegacyAgent。

```python
def try_create_agent(options, categories):
  if options.target != 'android':
    return False
  if options.from_file is not None:
    return AtraceAgent(options, categories)

  device_sdk_version = util.get_device_sdk_version()
  if device_sdk_version >= 18:
    if options.boot:
      # atrace --async_stop, which is used by BootAgent, does not work properly
      # on the device SDK version 22 or before.
      if device_sdk_version <= 22:
        print >> sys.stderr, ('--boot option does not work on the device SDK '
                              'version 22 or before.\nYour device SDK version '
                              'is %d.' % device_sdk_version)
        sys.exit(1)
      return BootAgent(options, categories)
    else:
      return AtraceAgent(options, categories)
  elif device_sdk_version >= 16:
    return AtraceLegacyAgent(options, categories)
```

systrace抓取的时候一般会指定category，或者叫tag，这些tag是采用位的形式来定义的，和Android系统中的`system/core/include/cutils/trace.h`文件中的tag一一对应(**源码注释中的文件是错误的**)。

```python
LEGACY_TRACE_TAG_BITS = (
  ('gfx',       1<<1),
  ('input',     1<<2),
  ('view',      1<<3),
  ('webview',   1<<4),
  ('wm',        1<<5),
  ('am',        1<<6),
  ('sm',        1<<7),
  ('audio',     1<<8),
  ('video',     1<<9),
  ('camera',    1<<10),
)
```

**3.5.2 FileReaderThread类**

该文件还定义了`FileReaderThread`类，继承自`threading.Thread`，用于在工作线程上不断地从文件或者管道中读取数据。`file_object`是对应的文件或者管道对象，`output_queue`是用来接收读取数据的队列，`text_file`是用来标示文件是否是文本文件，`chunk_size`是用来指定每次读取的数据的大小。如果text_file是True的话，说明是文本文件，那么chunk_size参数会被忽略，因为文本文件会一行一行地读取并处理。

```python
class FileReaderThread(threading.Thread):
  """Reads data from a file/pipe on a worker thread.

  Use the standard threading. Thread object API to start and interact with the
  thread (start(), join(), etc.).
  """

  def __init__(self, file_object, output_queue, text_file, chunk_size=-1):
    """Initializes a FileReaderThread.

    Args:
      file_object: The file or pipe to read from.
      output_queue: A Queue.Queue object that will receive the data
      text_file: If True, the file will be read one line at a time, and
          chunk_size will be ignored.  If False, line breaks are ignored and
          chunk_size must be set to a positive integer.
      chunk_size: When processing a non-text file (text_file = False),
          chunk_size is the amount of data to copy into the queue with each
          read operation.  For text files, this parameter is ignored.
    """
    threading.Thread.__init__(self)
    self._file_object = file_object
    self._output_queue = output_queue
    self._text_file = text_file
    self._chunk_size = chunk_size
    assert text_file or chunk_size > 0

  def run(self):
    """Overrides Thread's run() function.

    Returns when an EOF is encountered.
    """
    if self._text_file:
      # Read a text file one line at a time.
      for line in self._file_object:
        self._output_queue.put(line)
    else:
      # Read binary or text data until we get to EOF.
      while True:
        chunk = self._file_object.read(self._chunk_size)
        if not chunk:
          break
        self._output_queue.put(chunk)

  def set_chunk_size(self, chunk_size):
    """Change the read chunk size.

    This function can only be called if the FileReaderThread object was
    created with an initial chunk_size > 0.
    Args:
      chunk_size: the new chunk size for this file.  Must be > 0.
    """
    # The chunk size can be changed asynchronously while a file is being read
    # in a worker thread.  However, type of file can not be changed after the
    # the FileReaderThread has been created.  These asserts verify that we are
    # only changing the chunk size, and not the type of file.
    assert not self._text_file
    assert chunk_size > 0
    self._chunk_size = chunk_size
```

**3.5.3 AtraceAgent类**
 
AtraceAgent类的实现主要是在`start`方法中构建对应的atrace命令，然后利用`subprocess`模块去执行，最后在`collect_result`方法中解析systrace结果即可。其中的内部变量`_expect_trace`是用来指示这个命令是否会创建systrace数据，`_adb`表示`subprocess`执行的命令，`_trace_data`是指systrace的数据，`_tracer_args`是指systracer的参数。

```python
class AtraceAgent(systrace_agent.SystraceAgent):
  def __init__(self, options, categories):
    super(AtraceAgent, self).__init__(options, categories)
    self._expect_trace = False
    self._adb = None
    self._trace_data = None
    self._tracer_args = None
    if not self._categories:
      self._categories = get_default_categories(self._options.device_serial)

  def start(self):
    self._tracer_args = self._construct_trace_command()

    self._adb = do_popen(self._tracer_args)

  def collect_result(self):
    trace_data = self._collect_trace_data()
    if self._expect_trace:
      self._trace_data = self._preprocess_trace_data(trace_data)

  def expect_trace(self):
    return self._expect_trace

  def get_trace_data(self):
    return self._trace_data

  def get_class_name(self):
    return 'trace-data'
```

**3.5.3.1 _construct_trace_command方法**

`_construct_trace_command`方法的作用是构建atrace命令，其大致流程是：如果命令行中包含了`--list_categories`选项的话，那么就执行`adb [-e serial] shell atrace --list_categories`命令来获取所有的categories；如果命令行中包含了`--from_file`选项的话，那么就实际执行的是`cat {file}`命令(这个命令经常用于将一个压缩的systrace数据文件转换成html网页结果文件)；如果不是上面两种特殊情况，那么就正常解析命令行参数构建成atrace命令的参数，如果需要压缩数据的话就加上`-z`选项，如果设置了时间长度的话加上`-t {time}`选项，如果设置了buffer_size的话就加上`-b {buffer_size}`，而且如果设置了`sched`这个tag的话，需要将buffer_size设置为4096，因为默认情况下buffer_size是2048，而sched开启的话需要抓取的数据量会很大，所以设置成默认值的2倍。这部分命令行参数解析完了之后会调用`_construct_extra_trace_command`方法继续解析`-a`指定应用以及`-k`指定内核函数这两个参数。最后调用util.py中的`construct_adb_shell_command`方法将其封装成一个adb shell命令。

```python
def _construct_trace_command(self):
"""Builds a command-line used to invoke a trace process.

Returns:
 A tuple where the first element is an array of command-line arguments, and
 the second element is a boolean which will be true if the commend will
 stream trace data.
"""
if self._options.list_categories:
 tracer_args = self._construct_list_categories_command()
 self._expect_trace = False
elif self._options.from_file is not None:
 tracer_args = ['cat', self._options.from_file]
 self._expect_trace = True
else:
 atrace_args = ATRACE_BASE_ARGS[:]
 self._expect_trace = True
 if self._options.compress_trace_data:
   atrace_args.extend(['-z'])

 if ((self._options.trace_time is not None)
     and (self._options.trace_time > 0)):
   atrace_args.extend(['-t', str(self._options.trace_time)])

 if ((self._options.trace_buf_size is not None)
     and (self._options.trace_buf_size > 0)):
   atrace_args.extend(['-b', str(self._options.trace_buf_size)])
 elif 'sched' in self._categories:
   # 'sched' is a high-volume tag, double the default buffer size
   # to accommodate that
   atrace_args.extend(['-b', '4096'])
 extra_args = self._construct_extra_trace_command()
 atrace_args.extend(extra_args)

 tracer_args = util.construct_adb_shell_command(
     atrace_args, self._options.device_serial)

return tracer_args
```

**3.5.3.2 _collect_trace_data方法**

_collect_trace_data方法的作用是收集trace数据，它先会创建两个队列，一个是标准输出队列，另一个是错误输出队列，然后创建两个对应的工作线程FileReaderThread，它们分别监听标准输出流和错误输出流，前者不是文本数据类型，而后者是文本数据类型。方法中记录的时间的作用其实是为了在`status_update`方法中检测距离上一次更新时间的时间段，如果超过了`MIN_TIME_BETWEEN_STATUS_UPDATES`的话就输出一个`.`以便让使用者知道程序还在执行，而不是挂了。方法中后半部分内容就是在循环读取流中的数据，将其放入到队列中，直到没有任何数据了就关闭流，结束命令返回结果。

```python
def _collect_trace_data(self):
  # Read the output from ADB in a worker thread.  This allows us to monitor
  # the progress of ADB and bail if ADB becomes unresponsive for any reason.

  # Limit the stdout_queue to 128 entries because we will initially be reading
  # one byte at a time.  When the queue fills up, the reader thread will
  # block until there is room in the queue.  Once we start downloading the
  # trace data, we will switch to reading data in larger chunks, and 128
  # entries should be plenty for that purpose.
  stdout_queue = Queue.Queue(maxsize=128)
  stderr_queue = Queue.Queue()

  if self._expect_trace:
    # Use stdout.write() (here and for the rest of this function) instead
    # of print() to avoid extra newlines.
    sys.stdout.write('Capturing trace...')

  # Use a chunk_size of 1 for stdout so we can display the output to
  # the user without waiting for a full line to be sent.
  stdout_thread = FileReaderThread(self._adb.stdout, stdout_queue,
                                   text_file=False, chunk_size=1)
  stderr_thread = FileReaderThread(self._adb.stderr, stderr_queue,
                                   text_file=True)
  stdout_thread.start()
  stderr_thread.start()

  # Holds the trace data returned by ADB.
  trace_data = []
  # Keep track of the current line so we can find the TRACE_START_REGEXP.
  current_line = ''
  # Set to True once we've received the TRACE_START_REGEXP.
  reading_trace_data = False

  last_status_update_time = time.time()

  while (stdout_thread.isAlive() or stderr_thread.isAlive() or
         not stdout_queue.empty() or not stderr_queue.empty()):
    if self._expect_trace:
      last_status_update_time = status_update(last_status_update_time)

    while not stderr_queue.empty():
      # Pass along errors from adb.
      line = stderr_queue.get()
      sys.stderr.write(line)

    # Read stdout from adb.  The loop exits if we don't get any data for
    # ADB_STDOUT_READ_TIMEOUT seconds.
    while True:
      try:
        chunk = stdout_queue.get(True, ADB_STDOUT_READ_TIMEOUT)
      except Queue.Empty:
        # Didn't get any data, so exit the loop to check that ADB is still
        # alive and print anything sent to stderr.
        break

      if reading_trace_data:
        # Save, but don't print, the trace data.
        trace_data.append(chunk)
      else:
        if not self._expect_trace:
          sys.stdout.write(chunk)
        else:
          # Buffer the output from ADB so we can remove some strings that
          # don't need to be shown to the user.
          current_line += chunk
          if re.match(TRACE_START_REGEXP, current_line):
            # We are done capturing the trace.
            sys.stdout.write('Done.\n')
            # Now we start downloading the trace data.
            sys.stdout.write('Downloading trace...')

            current_line = ''
            # Use a larger chunk size for efficiency since we no longer
            # need to worry about parsing the stream.
            stdout_thread.set_chunk_size(4096)
            reading_trace_data = True
          elif chunk == '\n' or chunk == '\r':
            # Remove ADB output that we don't care about.
            current_line = re.sub(ADB_IGNORE_REGEXP, '', current_line)
            if len(current_line) > 1:
              # ADB printed something that we didn't understand, so show it
              # it to the user (might be helpful for debugging).
              sys.stdout.write(current_line)
            # Reset our current line.
            current_line = ''

  if self._expect_trace:
    if reading_trace_data:
      # Indicate to the user that the data download is complete.
      sys.stdout.write('Done.\n')
    else:
      # We didn't receive the trace start tag, so something went wrong.
      sys.stdout.write('ERROR.\n')
      # Show any buffered ADB output to the user.
      current_line = re.sub(ADB_IGNORE_REGEXP, '', current_line)
      if current_line:
        sys.stdout.write(current_line)
        sys.stdout.write('\n')

  # The threads should already have stopped, so this is just for cleanup.
  stdout_thread.join()
  stderr_thread.join()

  self._adb.stdout.close()
  self._adb.stderr.close()

  # The adb process should be done since it's io pipes are closed.  Call
  # poll() to set the return code.
  self._adb.poll()

  if self._adb.returncode != 0:
    print >> sys.stderr, ('The command "%s" returned error code %d.' %
                          (' '.join(self._tracer_args), self._adb.returncode))
    sys.exit(1)

  return trace_data
```

**3.5.3.3 _preprocess_trace_data方法**

_preprocess_trace_data方法是用来预处理trace数据的，atrace_agent.py文件中定义了很多`fix_xxx`的方法，用于修复trace数据中的部分数据，例如`fix_thread_names`用来修复线程名字，修复的方法是调用`ps -t`命令来获取当前系统中的线程的id及其对应的名称，其他的fix方法与之类似。

```python
  def _preprocess_trace_data(self, trace_data):
    """Performs various processing on atrace data.

    Args:
      trace_data: The raw trace data.
    Returns:
      The processed trace data.
    """
    trace_data = ''.join(trace_data)
    if trace_data:
      trace_data = strip_and_decompress_trace(trace_data)

    if not trace_data:
      print >> sys.stderr, ('No data was captured.  Output file was not '
                            'written.')
      sys.exit(1)

    if self._options.fix_threads:
      # Issue ps command to device and patch thread names
      ps_dump = do_preprocess_adb_cmd('ps -t', self._options.device_serial)
      if ps_dump is not None:
        thread_names = extract_thread_list(ps_dump)
        trace_data = fix_thread_names(trace_data, thread_names)

    if self._options.fix_tgids:
      # Issue printf command to device and patch tgids
      procfs_dump = do_preprocess_adb_cmd('printf "%s\n" ' +
                                          '/proc/[0-9]*/task/[0-9]*',
                                          self._options.device_serial)
      if procfs_dump is not None:
        pid2_tgid = extract_tgids(procfs_dump)
        trace_data = fix_missing_tgids(trace_data, pid2_tgid)

    if self._options.fix_circular:
      trace_data = fix_circular_traces(trace_data)

    return trace_data
```

**3.5.4 AtraceLegacyAgent类**

AtraceLegacyAgent继承自AtraceAgent，区别在于它适用于Android 4.1及以下系统，实现方式是重写了AtraceAgent中的_construct_list_categories_command和_construct_extra_trace_command方法，因为它们的命令行的参数选项略有不同。

```python
class AtraceLegacyAgent(AtraceAgent):
  def _construct_list_categories_command(self):
    LEGACY_CATEGORIES = """       sched - CPU Scheduling
        freq - CPU Frequency
        idle - CPU Idle
        load - CPU Load
        disk - Disk I/O (requires root)
         bus - Bus utilization (requires root)
   workqueue - Kernel workqueues (requires root)"""
    return ["echo", LEGACY_CATEGORIES]

  def start(self):
    super(AtraceLegacyAgent, self).start()
    if self.expect_trace():
      SHELL_ARGS = ['getprop', 'debug.atrace.tags.enableflags']
      output, return_code = util.run_adb_shell(SHELL_ARGS,
                                               self._options.device_serial)
      if return_code != 0:
        print >> sys.stderr, (
            '\nThe command "%s" failed with the following message:'
            % ' '.join(SHELL_ARGS))
        print >> sys.stderr, str(output)
        sys.exit(1)

      flags = 0
      try:
        if output.startswith('0x'):
          flags = int(output, 16)
        elif output.startswith('0'):
          flags = int(output, 8)
        else:
          flags = int(output)
      except ValueError:
        pass

      if flags:
        tags = []
        for desc, bit in LEGACY_TRACE_TAG_BITS:
          if bit & flags:
            tags.append(desc)
        categories = tags + self._categories
        print 'Collecting data with following categories:', ' '.join(categories)

  def _construct_extra_trace_command(self):
    extra_args = []
    if not self._categories:
      self._categories = ['sched', ]
    if 'sched' in self._categories:
      extra_args.append('-s')
    if 'freq' in self._categories:
      extra_args.append('-f')
    if 'idle' in self._categories:
      extra_args.append('-i')
    if 'load' in self._categories:
      extra_args.append('-l')
    if 'disk' in self._categories:
      extra_args.append('-d')
    if 'bus' in self._categories:
      extra_args.append('-u')
    if 'workqueue' in self._categories:
      extra_args.append('-w')

    return extra_args
```

**3.5.5 BootAgent类**

BootAgent同样继承自AtraceAgent，但是它适用于在设备启动的时候抓取systrace数据。它需要将指定的categories写入到`/data/misc/boottrace/categories`文件中，然后将`persist.debug.atrace.boottrace`属性置为1，最后执行重启`reboot`即可。待系统启动之后，利用Ctrl+C来结束抓取，此时会执行`atrace --async_stop`命令结束。在设备启动时抓取systrace数据的需求较少，所以`--boot`这个选项很少使用。

```python
class BootAgent(AtraceAgent):
  """AtraceAgent that specializes in tracing the boot sequence."""

  def __init__(self, options, categories):
    super(BootAgent, self).__init__(options, categories)

  def start(self):
    try:
      setup_args = self._construct_setup_command()
      try:
        subprocess.check_call(setup_args)
        print 'Hit Ctrl+C once the device has booted up.'
        while True:
          time.sleep(1)
      except KeyboardInterrupt:
        pass
      tracer_args = self._construct_trace_command()
      self._adb = subprocess.Popen(tracer_args, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
    except OSError as error:
      print >> sys.stderr, (
          'The command "%s" failed with the following error:' %
          ' '.join(tracer_args))
      print >> sys.stderr, '    ', error
      sys.exit(1)

  def _construct_setup_command(self):
    echo_args = ['echo'] + self._categories + ['>', BOOTTRACE_CATEGORIES]
    setprop_args = ['setprop', BOOTTRACE_PROP, '1']
    reboot_args = ['reboot']
    return util.construct_adb_shell_command(
        echo_args + ['&&'] + setprop_args + ['&&'] + reboot_args,
        self._options.device_serial)

  def _construct_trace_command(self):
    self._expect_trace = True
    atrace_args = ['atrace', '--async_stop']
    setprop_args = ['setprop', BOOTTRACE_PROP, '0']
    rm_args = ['rm', BOOTTRACE_CATEGORIES]
    return util.construct_adb_shell_command(
          atrace_args + ['&&'] + setprop_args + ['&&'] + rm_args,
          self._options.device_serial)
```

OK，本文的systrace工具源码分析结束，后面会抽空陆续加上Android系统中systrace相关的类和文件的源码解析，以及利用systrace数据来分析应用性能问题的方法。


