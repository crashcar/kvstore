# KVStore

## kv存储的应用场景

KV存储即键值(Key-Value)存储，是一种以键值对形式存储数据的数据库系统。在这种系统中，每个键都唯一地标识了与之相关联的值。这种存储方式简单而高效，以下列举一些常见的应用场景

1. **缓存系统**

    在Web应用中，为了减少数据库查询次数和加快响应速度，可以将经常访问的数据（如用户信息、商品详情）存储在KV缓存中。用户再次请求相同数据时，系统会先在KV缓存中查找，如果找到，就直接返回数据，从而减轻数据库负担。

    - **Key**：查询的唯一标识符，如数据库查询语句的哈希值或特定资源的ID。
    - **Value**：查询结果或资源的数据。

2. **会话存储**

    在用户登录网站后，系统会在KV存储中创建一个会话记录，将用户的会话ID作为键，会话信息作为值。这样，用户在浏览网站时，系统可以通过会话ID快速检索其会话信息，保持用户状态和偏好。

    - **Key**：用户的会话ID或Cookie。
    - **Value**：用户的会话数据，如登录状态、购物车内容、偏好设置等。

3. **实时数据分析**

    在实时数据分析中，如监控系统，KV存储可以快速接收并存储由传感器或日志生成的数据流。分析工具可以实时访问这些数据进行处理和分析，以快速做出决策或触发警报。

    - **Key**：数据标识符，如时间戳、事件ID或用户ID。
    - **Value**：实时生成的数据内容，如用户行为日志、传感器数据等。

4. **分布式系统中的元数据管理**

    在分布式文件系统中，KV存储可以用来保存文件的元数据。系统通过键（文件路径）快速访问文件的详细信息，从而有效管理文件系统。

    - **Key**：资源的唯一标识，如文件名或路径。
    - **Value**：文件或资源的元数据，如大小、创建时间、权限等。

5. **排行榜和计数器**

    在游戏或社交媒体平台中，可以使用KV存储管理排行榜或计数器。系统可以实时更新键对应的值，以反映玩家得分或帖子的点赞数。

    - **Key**：排行榜项目的标识符，如游戏用户名或帖子ID。
    - **Value**：相关数据，如分数、点赞数或评论数。

## 项目结构

<img width="760" alt="image" src="https://github.com/crashcar/kvstore/assets/56828380/4497cf73-4846-46a5-8532-2c24fe1905ee">


<img width="861" alt="image" src="https://github.com/crashcar/kvstore/assets/56828380/50bc2445-f0db-417a-80d7-06a9c84f158b">


### 网络模块

网络模块负责接收客服端的连接，连接后接收客户端的原始数据以及发送查询或者处理的结果，目前实现的有

- **基于 Epoll 的 reactor，测试实现 100w 的并发连接量**

    Reactor 模式是一种事件驱动的设计模式，用于处理服务端的并发I/O。在这个模式中，有一个中心的事件循环（Reactor），负责监听所有I/O事件（如网络请求），并将这些事件分发给相应的处理器进行处理。这种模式非常适合于高性能网络服务器，因为它能够有效地管理大量并发连接，而不需要为每个连接分配一个独立的线程，这在很大程度上减少了资源的消耗和上下文切换的开销。

- **基于开源的协程框架 NtyCo 的协程版本的 reactor，协程在 reactor 的基础之上更高效的处理并发的方法**

    只使用`epoll`的模型中，所有事件的处理是串行的，即便是`epoll`提供了一种有效的方式来并发监控多个文件描述符的I/O事件，实际的事件处理逻辑仍然是顺序执行的。协程允许在等待I/O操作时，以非常低的成本切换到其他任务执行，从而保持CPU的忙碌和提高程序的吞吐量。此外，协程支持使用同步的编程风格来编写异步代码，这使得代码更加直观和易于理解。

### 协议解析模块

负责对收到的数据按照协议进行解析

协议接收的输入字符串以 `" "` 空格作为分隔符，解析前 3 个子字符串，第一个字符串为指令 `CMD`，第二个和第三个子字符串为 `Key` 和 `Value`。`CMD` 包括：

- (R/H)SET：接收 key、value
- (R/H)GET：接收 key
- (R/H)MOD：接收 key、value
- (R/H)DEL：接收 key
- (R/H)COUNT：不接受其他参数

其中(R/H)表示在原始的 CMD 前面加 R/H 表示使用红黑树或/哈希存储引擎

### KV 引擎模块

提供 数组、红黑树、哈希表 三种 KV存储引擎，分别都实现了 5 个对外的接口函数：set、get、mod、del、count，以及 2 个 create、destory 函数，并且使用适配层进行了适配操作

- 红黑树

    红黑树是一种自平衡的二叉搜索树，它在广泛用于构建高效的搜索和排序数据结构。拥有自平衡性质、高效的查找性能、优化的内存使用、以及很强的适应性。这些特性确保了KV存储系统即使在处理大量数据和频繁更新操作时也能保持高效和稳定的性能

- 哈希表

    哈希表是一种通过哈希函数将键（key）映射到表中一个位置以便快速访问记录的数据结构。它支持高效的插入、查找和删除操作，通常在最佳情况下这些操作的时间复杂度为O(1)。哈希表提供了快速的数据访问速度、高效的数据操作能力和良好的扩展性

## 性能测试

1. io并发量

    - epoll-reactor：100w（NtyCo还没测）
    - 同时 3 个客户端
    - 10 个监听端口
    - 本地测试时受限于**虚拟机**、**网络模式**、**虚拟网卡**：**并发量 vmfusion>UTM，桥接 > NAT，vmxnet3 > virtue-net-pci**

2. qps

    - rbtree：2.4w

        <img width="558" alt="image-20240330235202072" src="https://github.com/crashcar/kvstore/assets/56828380/e30a0c31-09fb-4119-b5ae-df21b2541c2b">


    - hashtable：2.3w

        <img width="551" alt="image-20240330235243617" src="https://github.com/crashcar/kvstore/assets/56828380/0fd90be6-8158-4bac-b436-f7550d910180">


3. testcase

    <img width="562" alt="image-20240330235309897" src="https://github.com/crashcar/kvstore/assets/56828380/517b8cb7-a5bf-4dea-8c38-35bc7fdf6036">


