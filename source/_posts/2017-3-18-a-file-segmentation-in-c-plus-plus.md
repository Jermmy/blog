---
title: 用C++写一个文件分割器
date: 2017-03-18 15:48:21
tags: [c++]
categories: c++
---

在成功将 mac 由 10.10 升级到 10.12 后，我发现除了新增一个并不怎么好用的 Siri 外，原来支持 NTFS 硬盘的驱动居然也成功失效了。我那块 500 GB 的东芝硬盘，虽不至于成砖，但一块只能读不能写的硬盘，实在让人欲哭无泪。巧的是，最近需要频繁地将一些数据文件( GB 级别)拷贝到其他电脑，而手头又仅剩一些小容量 U 盘。于是，我突然萌生了写一个文件分割器的想法，将大的压缩文件分片后，再用这些小 U 盘搬到到其他电脑上去。

有人会问，这样的软件明明网上有的是，何必自己写呢？没错，我就是这么无聊的人。

<!--more-->

### 需求分析

其实也不用怎么分析，功能非常简单。我需要两个函数（分别用于分割和合成），分割函数的输入是：一个文件、分片数量，输出是：分片文件、一个配置文件（记录分片文件的顺序）；合成函数的输入是：配置文件（根据配置，程序会寻找分片文件用于合成）。

基于此，其实要实现的是两个这样的函数：

```c++
// 分割文件的函数，第三个参数指定配置文件名称
void segment(string file_name, int segment_num, string json_file);
// 合成文件的函数，参数为分割时生成的配置文件
void merge(string json_file);
```

配置文件的格式，我使用了 `json`（其实用简单的字符串记录一下也是可以的）。

另外，为了方便使用，最好再用一个类将两个方法封装一下。

### 难点分析

这么小的程序会有难点？！其实还是有一丢丢，就是切割文件的时候，由于文件可能太大，因此不能一口气读入内存中，所以这里采用分块的方法，读一小块写一小块。当然啦，速度方面的优化，这里先不考虑了。

### 程序实现

首先，我们把所有功能放在一个类`FileSegment`里面实现，对外只暴露上面的两个函数接口。

#### segment

上面的难度分析已经指出，我们需要分块读取文件，然后分块写入。

首先需要定义分块大小：`const int FileSegment::kBlockSize = 1024 * 1024;` ，这里设定一个块大小为1 MB。

我们再定义两个辅助函数，用来分块读文件、写文件：

```c++
// 从input流中读取size(默认大小kBlockSize)大小的字节到data里面
inline void read_file_in_block(char* data, ifstream &input, int size=kBlockSize) {
    input.read(data, size);
}
// 从data中将size(默认大小kBlockSize)大小的字节写入到output流
inline void write_file_in_block(char* data, ofstream &output, int size=kBlockSize) {
    output.write(data, size);
}

```

这两个函数因为要经常用到，所以把它们作为内联函数使用。

综合这两个辅助函数，我们定义另一个辅助函数，用于从输入文件中将大批量的数据写入到输出文件中：

```c++
// 将input流中读取input_size大小的字节内容，写入到output流中
void FileSegment::copy_file(ifstream &input, ofstream &output, size_t input_size) {
	char* data = new char[kBlockSize];
    
    for (size_t block = 0; block < input_size / kBlockSize; block++) {
    	read_file_in_block(data, input);
    	write_file_in_block(data, output);
    }

    // 读取剩余的字节
    size_t left_size = input_size % kBlockSize;
    if (left_size != 0) {
    	read_file_in_block(data, input, left_size);
    	write_file_in_block(data, output, left_size);
    }

	delete [] data;
	data = nullptr;
}
```

有了上面的辅助函数后，我们可以聚焦于`segment()`函数的核心代码部分了。

我们只需要利用`copy_file()`函数，将源文件分片写入到几个分片文件中即可。

```c++
// 分片文件名
vector<string> segment_files;
for (int i = 0; i < segment_num; i++) {
  segment_files.push_back(file_name + to_string(i+1) + ".tmp");
  cout << "segment_file --- " << segment_files[i] << endl;
}

ifstream src_file_input(file_name);
// 输入文件大小
size_t src_file_size = file_size(src_file_input);
// 分片文件大小
size_t segment_size = src_file_size / segment_num;

// 分片输出文件
for (int i = 0; i < segment_num; i++) {
  ofstream segment_file_output(segment_files[i]);
  if (i == segment_num-1) {  // 最后一次，要将剩余文件片全部写入
    size_t left_size = src_file_size % segment_size;
    copy_file(src_file_input, segment_file_output, segment_size + left_size);
  } else {
    copy_file(src_file_input, segment_file_output, segment_size);
  }
  segment_file_output.close();
}

src_file_input.close();
```

另外，我们需要将分片文件的文件名和分割顺序等信息写入配置文件中，这里使用`json`格式，并用这个[第三方库](https://github.com/nlohmann/json)来操纵`json`对象。

```c++
const string FileSegment::kSegmentFileNum = "SegmentNum";
const string FileSegment::kSourceFileName = "SourceFileName";
const string FileSegment::kSegmentFiles = "SegmentFiles";

ofstream json_output(json_file);
json j;
j[kSegmentFileNum] = segment_num;
j[kSourceFileName] = file_name;
j[kSegmentFiles] = segment_files;   // 这里segment_files是vector对象
json_output << j;
json_output.close();
```

下面给出`segment()`函数的完整代码：

```c++
void FileSegment::segment(string file_name, int segment_num, string json_file) {

	// 检查源文件是否存在
    if (!exist(file_name)) {
    	cout << "file [" << file_name << "] doesn't exist!" << endl;
    	return;
    }

    // 检查分片数量是否大于0
    if (segment_num <= 0) {
    	cout << "segment number should be greater than 0!" << endl;
    	return;
    }

    // 分片文件名
    vector<string> segment_files;
    for (int i = 0; i < segment_num; i++) {
    	segment_files.push_back(file_name + to_string(i+1) + ".tmp");
    	cout << "segment_file --- " << segment_files[i] << endl;
    }

    ifstream src_file_input(file_name);
    // 输入文件大小
    size_t src_file_size = file_size(src_file_input);
    // 分片文件大小
    size_t segment_size = src_file_size / segment_num;

    // 分片输出文件
    for (int i = 0; i < segment_num; i++) {
    	ofstream segment_file_output(segment_files[i]);
    	if (i == segment_num-1) {  // 最后一次，要将剩余文件片全部写入
    		size_t left_size = src_file_size % segment_size;
    		copy_file(src_file_input, segment_file_output, segment_size + left_size);
    	} else {
    		copy_file(src_file_input, segment_file_output, segment_size);
    	}
    	segment_file_output.close();
    }

    src_file_input.close();

	ofstream json_output(json_file);
	json j;
	j[kSegmentFileNum] = segment_num;
	j[kSourceFileName] = file_name;
	j[kSegmentFiles] = segment_files;
    json_output << j;
	json_output.close();
}
```

#### merge

有了前面的辅助函数后，`merge()`函数的实现基本是依葫芦画瓢。首先需要从配置文件中读取出`json`对象，根据配置信息去合成文件：

```c++
json j;

if (!exist(json_file)) {
  cout << "json file [" << json_file << "] doesn't exist!" << endl;
  return;
}

ifstream json_input(json_file);
json_input >> j;

// 源文件名
string src_file = j[kSourceFileName];

// 检查源文件是否已经存在
if (exist(src_file)) {
  src_file += ".copy";
}
ofstream result(src_file);

// 文件分片数量
int segment_num = j[kSegmentFileNum];
// 分片文件名
vector<string> segment_files = j[kSegmentFiles];
```

之后，根据分片文件来合成大文件：

```c++
// 合并文件
for (auto it = segment_files.begin(); it != segment_files.end(); it++) {
  cout << "copy file [" << *it << "]" << endl;
  ifstream seg_input(*it);
  size_t seg_input_size = file_size(seg_input);  // 计算分片文件大小
  copy_file(seg_input, result, seg_input_size);
  seg_input.close();
}
```

接下来照例给出`merge()`函数完整实现：

```c++
void FileSegment::merge(string json_file) {
	json j;

	if (!exist(json_file)) {
		cout << "json file [" << json_file << "] doesn't exist!" << endl;
		return;
	}

	ifstream json_input(json_file);
	json_input >> j;

	// 源文件名
	string src_file = j[kSourceFileName];

    // 检查源文件是否已经存在
	if (exist(src_file)) {
		src_file += ".copy";
	}
	ofstream result(src_file);

    // 文件分片数量
	int segment_num = j[kSegmentFileNum];
    // 分片文件名
    vector<string> segment_files = j[kSegmentFiles];

    // 检查文件分片是否齐全
    for (auto it = segment_files.begin(); it != segment_files.end(); ++it) {
    	if (!exist(*it)) {
    		cout << "segment file [" << *it << "] doesn't exist!" << endl;
    		return; 
    	}
    }

    // 合并文件
    for (auto it = segment_files.begin(); it != segment_files.end(); it++) {
    	cout << "copy file [" << *it << "]" << endl;
    	ifstream seg_input(*it);
    	size_t seg_input_size = file_size(seg_input);
    	copy_file(seg_input, result, seg_input_size);
    	seg_input.close();
    }

	json_input.close();
	result.close();
}
```

<br\>

#### main

在`main()`中，直接实例化`FileSegment`类，通过`segment()`和`merge()`函数分割或者合成文件。

```c++
int main(int argc, char const *argv[]) {
  FileSegment fs;
  // 分割data.zip文件，分为4片
  fs.segment("data.zip", 4, "config.json");
  // 根据config.json文件合成最终文件
  fs.merge("config.json");
}
```

另外，为了方便使用，我特意写了一个解析命令的类`InputParser`，然后，我们可以按照如下方式使用该程序：

**分割文件**

`./main -s data.zip 4 config.json` 

**合成文件**

`./main -m config.json`





















