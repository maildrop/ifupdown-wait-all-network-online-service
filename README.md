# ifupdown-wait-all-network-online-service
Debian で ifupdown によるネットワーク構成で、全てのインターフェースを待つスクリプト

## モチベーション
マルチホーム環境のDebianにおいて、network-online.targetによる待機が上手く動かないことがある。

DebianのSystemdではネットワークインターフェースのコンフィギュレーションを待機するためには、 network-online.target を UnitセクションのAfter に書いておく
```
[Unit]
After=network-online.target
```

そして、このnetwork-online.target を実際に待機させるためには、
ifupdownを使ったネットワーク構成の場合は、ifupdown-wait-online.service を使用する。
（構成の方法によっては別の方法があるらしい。伝統的な /etc/network/interfaces において設定した時には、
ifup ipdown によってインターフェースのup/down が制御される。
これに対応した wait-oneline が ifupdown-wait-online.service である）

そして、これは

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

```ifupdown-wait-online.service``` -&gt; ```network-online.target``` -&gt; ```misc daemons```

の順番に立ち上がる。

## 問題

そこで、 /lib/ifupdown/wait-online.sh の中身を見てみると
設定ファイルは ```/etc/default/networking``` で変数のオーバーライドをしている。
そして、いくつかの方法でインターフェースの立ち上がりを確認する方法を提供している。

この方法は WAIT_ONLINE_METHOD で指定出来る 

|WAIT_ONLINE_METHOD| 内容 |
|route             |デフォルトルートが指定されているかどうかを確認する。|
|ping / ping6      |```WAIT_ONLINE_ADDRESS``` に指定されているアドレスに ping を投げるのだが、これはワンショットなので問題外。待たない。|
|ifup iface interface| この方法は```/etc/network/interfaces```に書かれている内容を ifquery を使用して、取ってくる。

* ```auto eth0``` 等 auto で指定しているインターフェースに関しては全てのインターフェースが上がっている
* ```hot-plug ``` で指定されているインターフェースに関しては、いずれか一つ以上
* ```WAIT_ONLINE_IFACE``` でインターフェースが指定されているときには、いずれか 一つ以上

ただし、これは ifup が実行されたのみであって、IPアドレスが割り当てられた ということを意味しない。
（これは、無線LANのように インターフェースが存在して linkup している ような状況を想定していると考える）|

というように、マルチホーム環境のサーバ機で使うには大変不安定になるので、本スクリプトを書き下ろした。

## 手法

### ```ifupdown-wait-all-online.sh```の説明
このファイルは、 /usr/local/sbin/ifupdown-wait-all-online.sh に配置する
ifquery --list と、 変数 ADDTIONAL_DEVICES に列挙したインターフェースに対して、ipコマンドで

- 実際にデバイスが存在するか？ ip link show で確認
- ip addr show でアドレスが存在するか確認
 - WITHOUT_INET4_DEVICE に列挙したインターフェースは、 IPv4 アドレスが割り当てられる必要は無い
 - WITHOUT_INET6_DEVICE に列挙したインターフェースは、 IPv6 アドレスが割り当てられる必要は無い

WITHOUT_INET6_DEVICE があるのは、 IPoE(IPv4 over IPv6 , ipip6) のインターフェースに対応させるため。
特に今回の IPv4 over IPv6 のトンネルインターフェースは、IPv6 のネットワークコンフィギュレーションが終わって
IPv6アドレスが割り振られた後でしか、IPv6のローカルアドレスが設定出来ないため auto 指定できない問題がある。
そして、このインターフェースには、IPv6 が割り当てられないので、WITHOUT_INET6_DEVICEが指定出来るようにしてある。

他方の IPv6 over IPv4 に関しても同様に、WITHOUT_INET4_DEVICEの指定が出来るようにしてある。
[ds-liteの設定スクリプト](https://gist.github.com/maildrop/4c32461685bc7d5c8969cc1f7a5ce38e#file-dslite-tunnel)

そして、本スクリプトは、 ifquery --list と ADDTIONAL_DEVICES のインターフェースに対して
IPv4 IPv6 アドレスが割り当てられたときに、終了する。

### ```ifupdown-wait-all-network.service``` の説明
このファイルは、```/etc/systemd/system/ifupdown-wait-all-network.service``` に配置する

```
[Unit]
Before=network-online.target
```
で指定されているので、
network-online.targetがupする事を、ifupdown-wait-all-network.service がupするまで遅延させる。
（ifupdown-wait-online.service と同じ）
