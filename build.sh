# docker build --build-arg "HTTP_PROXY=http://172.17.42.1:3128/" -t coreindustries/digits-tensorflow .
# docker build --build-arg "HTTP_PROXY=http://10.11.2.181:3128/" -t coreindustries/digits-tensorflow .

# https://stackoverflow.com/questions/22030931/how-to-rebuild-dockerfile-quick-by-using-cache/22089946#22089946
# get squid ip to use in docker build
SQUID_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' squid)

# build your instance
docker build --build-arg http_proxy=http://$SQUID_IP:3128 --build-arg https_proxy=https://$SQUID_IP:3128 -t coreindustries/digits-tensorflow .