
{
  description = "My DEV templates";

  outputs = { self, ... }: {
    templates = {
      josso-pxy = {
        path =./josso-pxy;
        description = "JOSSO Proxy using NGINX, SSL and self-signed certificates";
      };
    };
  };
}