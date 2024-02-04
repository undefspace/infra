.PHONY: deploy
deploy/%:
	$(MAKE) send-secrets/$*
	nixos-rebuild switch --target-host root@$* --flake .#$*  --fast -v --use-substitutes

.PHONY: send-secrets
send-secrets/%:
	YOLO=YES scripts/send-secrets.sh $*
