---
title: CS144 - Networking Lab 心得体会
date: 2024-02-18 21:07:25
tags:
---
最近在做2024 winter的cs144的实验，顺带复习一下计网的相关内容。

#### 课程主页：[CS 144: Introduction to Computer Networking, Winter 2024](https://cs144.github.io/)

#### 环境配置：
1. 为了方便选择在本地搭建虚拟机进行测试，课程提供了非常详细的虚拟机镜像和安装、配置[教程](https://stanford.edu/class/cs144/vm_howto/vm-howto-image.html)，不在赘述。
2. 建设好虚拟机后，为了小命和使用体验，请第一时间换源(最近发现ustc的镜像站可以直接通过`wget`下载到换源后的source.list，解决了换源时候虚拟机和宿主机之间粘贴板不互通的问题)(~~主要还是我懒得装增强插件~~)
3. 安装必要的运行环境：
    ```bash
    $ sudo apt update && \
      sudo apt install git cmake gdb build-essential clang \
                       clang-tidy clang-format gcc-doc \
                       pkg-config glibc-doc tcpdump tshark
    ```
4. 最后就是`clone`下来实验的[源代码](https://github.com/cs144/minnow)以及设置自己仓库的过程。

### Lab 0 :
1. Networking by hand  
    这个实验没啥说的，跟着文档做就好了。
    ![Fetch a Web page](images/cs144/lab0-1.png)
2. Writing webget
    这个就是在`apps/webget.cc`中实现一个和上面图片所示过程相同的程序，在看完`util/socket.hh`中提供的接口后就可以动手了。  有一些需要注意的细节：
    - 在`HTTP`中，每一行必须以`“\r\n”`结束
    - 写完后在`build/`文件夹下运行`make`，编译通过后运行`./build/apps/webget cs144.keithw.org /hello`，如果结果和上面手动执行时的到的结果一样就好了
3. An in-memory reliable byte stream
    在这一节中，大致就是需要我们在`src/byte stream.hh`和`src/byte stream.cc`中实现一个数据结构，它能够实现边读边写且要求**有序读出**，同时还存在一个上限`capacity_`和一些标志位。  
    这个`ByteStream`的设计是有点类似于`C++`里基于流的`IO`的，和`stringstream`的功能差不多，都是实现基于`char`的流，不过`bs`和`ss`不同的是`bs`是`FILO`的，而`ss`是`FIFO`的，换言之我们的bs在这里像一个“滑动窗口”——-而且左右指针都始终向一个方向前进，这意味着如果我们像`ss`一样利用`string`这种简单的连续内存空间来维护我们的数据的话，将会造成左侧内存的浪费———写指针永远无法到达它以前到过的地方，因为它是单向运动的，此外它还无法实现完美转发，因为我们使用`operator+=`衔接串的话势必需要一次拷贝。  
    在考虑到这个问题后，其实就能意识到应该用`queue<string>`来实现了，至于为什么不用`queue<char>`也很好理解，因为`push`接受的是一个`string`，这势必会导致拆解过程，其中又包含了一次拷贝，会浪费很多时间和空间。
    此外还有一个问题是`pop`函数要求能够弹出任何合法数量的在字符`char`而不是字符串`string`，因此我们还需要单独维护一个指针用于指向队首字符串的起始位置，课程提供的代码其实也提示我们了这个细节，并且要求我们使用`C++17`提出的`std::string_view`来实现。
    在具体的实现过程中还需要注意一些不起眼但是会影响结果的细节问题，如`buffer_data.size()`与`bytes_buffered()`的区别等等。
    实现完成后在根目录下运行`cmake --build build --target check0`测试就好了。最后附上我的结果：  
    ![result for BS](images/cs144/lab0-2.png)

### Lab 1：
待更新
