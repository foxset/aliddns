**动态域名解析**

  利用GitHub Actions的定时任务，实现域名动态解析

  一般的ipv6动态域名解析的脚本，都要获取运行在本台设备上，从本台设备网卡上获取ipv6地址，然后比对进行更新。但那样就需要每台设备都开机，明显不经济。

  研究ipv6地址特性发现：ipv6地址分为8段，前4段局域网内设备都一样（光猫本身除外），不同设备的差异主要区别在后4段，设备的后4段可以按MAC地址设置成固定是不变的。

  利用ipv6的这个特性，只要知道局域网的前4段，及设备的固定后4段，可以用脚本拼接成一个新的完整的ipv6地址，然后进行动态域名解析，这样机器一开机，就能用早已经更新好的域名访问了。
