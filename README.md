# ifupdown-wait-all-network-online-service
Debian で ifupdown によるネットワーク構成で、全てのインターフェースを待つスクリプト

## モチベーション
Debin で ifupdown を使ったネットワーク構成をする時に、ifupdown-wait-online.service でインターフェースの待機をする
これは

/lib/systemd/system/ifupdown-wait-online.service
```
[Unit]
Description=Wait for network to be configured by ifupdown
DefaultDependencies=no
Before=network-online.target
ConditionFileIsExecutable=/sbin/ifup

[Service]
Type=oneshot
ExecStart=/lib/ifupdown/wait-online.sh
RemainAfterExit=yes

[Install]
WantedBy=network-online.target
```
で定義されているように ```/lib/ifupdown/wait-online.sh``` スクリプトでインターフェースを待機する。

殆どのネットワークデーモン類は After=network.target network-online.target nss-lookup.target
で network-online.target より後に起動するようにしているので、

```ifupdown-wait-online.service``` -&gt; ```network-online.target``` -&gt ```misc daemons```

の順番に立ち上がる。


そこで、 /lib/ifupdown/wait-online.sh の中身を見てみると
設定ファイルは ```/etc/default/networking``` で変数のオーバーライドをしている。
そして、いくつかの方法でインターフェースの立ち上がりを確認する方法を提供している。

この方法は WAIT_ONLINE_METHID で指定出来る 

### route
デフォルトルートが指定されているかどうかを確認する。

### ping / ping6
```WAIT_ONLINE_ADDRESS``` に指定されているアドレスに ping を投げるのだが、これはワンショットなので問題外。待たない。

### ifup iface interface
 この方法は```/etc/network/interfaces```に書かれている内容を ifquery を使用して、取ってくる。

* ```auto eth0``` 等 auto で指定しているインターフェースに関しては全てのインターフェースが上がっている
* ```hot-plug ``` で指定されているインターフェースに関しては、いずれか一つ以上
* ```WAIT_ONLINE_IFACE``` でインターフェースが指定されているときには、いずれか 一つ以上

ただし、これは ifup が実行されたのみであって、IPアドレスが割り当てられた ということを意味しない。
（これは、無線LANのように インターフェースが存在して linkup している ような状況を想定していると考える）


というように、マルチホーム環境のサーバ機で使うには大変不安定になるので、本スクリプトを書き下ろした。



