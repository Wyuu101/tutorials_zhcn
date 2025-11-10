## 个人笔记

在跟着README进行学习时自己手动查看了一下h1在两种参数下发送的数据包


###  1、不使用隧道的情形
  ```bash
  ./send.py 10.0.2.2 "P4 is cool"
  ```
![](./note1.png)

### 2、使用隧道
  ```bash
  ./send.py 10.0.2.2 "P4 is cool" --dst_id 2
  ```
![](./note2.png)

