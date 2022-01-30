# Test Framework

## Container Usage

```bash
# build container image
podman build . -t aliyun-performance-validation

# correct SELinux context for container
chcon -R -u system_u -t svirt_sandbox_file_t $HOME/.aliyun/config.json
chcon -R -u system_u -t svirt_sandbox_file_t $HOME/mirror/codespace/aliyun_performance_validation/
chcon -R -u system_u -t svirt_sandbox_file_t $HOME/.pem/

# run as debug container
podman run --rm -it --name aliyun-performance-validation \
    --volume $HOME/.aliyun/config.json:/root/.aliyun/config.json:ro \
    --volume $HOME/mirror/codespace/aliyun_performance_validation/:/root/workspace/repo:rw \
    --volume $HOME/.pem/cheshi-docker.pem:/root/.pem/cheshi-docker.pem:ro \
    aliyun-performance-validation /bin/bash

# start the testing
export ALICLOUD_ACCESS_KEY="$(cat ~/.aliyun/config.json | jq -r '.profiles[0].access_key_id')"
export ALICLOUD_SECRET_KEY="$(cat ~/.aliyun/config.json | jq -r '.profiles[0].access_key_secret')"

# following the notes.md in each sub test folder...

```
