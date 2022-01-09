all:

clean:

install:
	cp ifupdown-wait-all-network.service /etc/systemd/system/
	install ifupdown-wait-all-online.sh /usr/local/sbin
	systemctl daemon-reload
