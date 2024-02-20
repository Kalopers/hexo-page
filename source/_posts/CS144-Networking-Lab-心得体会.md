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
4. 然后是设置自己仓库的过程，先fork一个[原仓库](https://github.com/CS144/minnow)，记得取消勾选`Copy the main branch only`(否则拉取不到后续实验的内容)，然后再在虚拟机上`clone`就好了。最后就是根据个人习惯用自己习惯的工具链~~愉快的~~完成实验啦！

<!--more-->

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
    ![Result for ByteStream](images/cs144/lab0-2.png)

### Lab 1：
1. Getting started  
    这个实验源代码和文档都有点抽象。。。之前没有注意，fork仓库时候只fork了main，导致拉取不到lab 1的代码，不得不删了重新fork。然后跟着文档拉取、合并就好了：
    ```bash
    $ git merge origin/check1-startercode
    $ git merge upstream/check1-startercode
    $ cmake -S . -B build
    $ cmake --build build
    ```
2. 任务理解和实现思路
    吐槽一下这个实验文档，写的有点太抽象了(~~读的我丧失语言能力了~~)，没表述清楚输入啥输出啥，最后还是对着代码提供的注释大概看明白了。  
    下面是我大概的理解：
    - 实现一个名为 Reassembler 的类，其主要功能是处理数据插入，包含的重要成员有 insert 函数 和 ByteStream 类型的变量 output_ 。考虑到 ByteStream 对顺序输入的要求以及可能存在推送来的数据乱序和重复问题，因此我们需要在 insert 函数中将外部应用传入的数据和对应的索引排序好，最后传入到 out_put_ 中。
    - 正如上面所说的顺序的问题，因此必然存在部分提前到达的数据无法被立刻推送进 out_put_ ，我们便需要在 Reassembler 类中实现一个可以暂时存储数据的数据结构。根据上面的原因，不难发现我们需要大量的对这个数据结构进行读取和插入，因此对相关的性能要求很高。根据这个原因，我们很容易选择出 map 或者 list ，但是又因为我们的查找是要查找两个端点，如果将左右区间的 pair 作为 key 的话就不能用它内置的二分查找算法——它无法传递自定义比较谓词，而使用$<algorithm>$中的二分算法的话又因为它的迭代器不满足随即迭代器的条件，意味着只能$O(n)$查找。综合来看，我们维护一个有序链表是最优的。
    - 整个 Reassembler 的功能其实有些类似于滑动窗口，实现过程也可能到新插入的数据填补缓存中的空隙，甚至与原有数据发生重叠，也就是区间合并问题，可以参考[LeetCode 57.插入区间](https://leetcode.cn/problems/insert-interval/description/)。我的实现和大部分题解都是重新定义了一个容器，这样在算法题中是可行的，因为它只有$O(1)$的空间复杂度(除了存储答案的空间)和$O(n)$的时间复杂度，但是在生产中我们就不能再忽略存储答案的空间了，不然势必会导致极大的内存浪费。最后参考网友给出的在原容器上增删的[实现](https://leetcode.cn/problems/insert-interval/solutions/472151/cha-ru-qu-jian-by-leetcode-solution/comments/2108778)。
    - 最后就是具体实现上的一些细节问题，如边界的处理(是否包含这个边界)，如溢出处理(重叠部分的处理，左截断还是右截断)等等。
    - 有一个我遇到的小bug贴出来：我实现的 ByteStream 类的 push 函数是会根据 available_capacity() 直接截断传入的 data 参数的，因此在下一个可以被输出的变量的标记位时一定要先加上 data.size() 再 push 到 out_put_ 中。  
    最后贴上我的结果：
    ![Result for Reassembler](images/cs144/lab1-1.png)

### Lab 2:
待更新。


    
    

