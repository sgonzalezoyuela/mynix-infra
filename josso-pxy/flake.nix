{
  description = "JOSSO Proxy w/SSL Docker image";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

        in

        rec {
          packages = {
            nginx =
              let
                # JOSSO server to proxy (TODO: make it configurable using env vars in the container)
                jossoHost = "localhost";
                jossoPort = "8081";
                
                # nginx settings
                nginxPort = "443";
                nginxConf = pkgs.writeText "nginx.conf" ''
                  user nobody nobody;
                  daemon off;
                  error_log /dev/stdout info;
                  pid /dev/null;
                  events {}
                  http {
                    access_log /dev/stdout;
                    server {
                      listen ${nginxPort} ssl;

                      ssl_certificate /etc/nginx/ssl/cert.pem;
                      ssl_certificate_key /etc/nginx/ssl/key.pem;
                      index index.html;
                      location / {
                        # root ${nginxWebRoot};
                        proxy_pass http://localhost:8081;
                      }
                    }
                  }
                '';
                nginxWebRoot = pkgs.writeTextDir "index.html" ''
                  <html><body><h1>Hello from NGINX</h1></body></html>
                '';
              in
              pkgs.dockerTools.buildLayeredImage {
                name = "atricore/josso-pxy";
                tag = "latest";

                # fakeNss
                # Provides /etc/passwd and /etc/group that contain root and nobody. 
                # Useful when packaging binaries that insist on using nss to look up username/groups (like nginx).

                contents = [
                  #pkgs.bashInteractive
                  pkgs.dockerTools.fakeNss
                  pkgs.nginx
                  #pkgs.exa
                  pkgs.openssl
                ];

                extraCommands = ''

                mkdir -p etc/nginx/ssl

                ${pkgs.openssl}/bin/openssl req -x509\
                 -newkey rsa:4096\
                 -keyout etc/nginx/ssl/key.pem\
                 -out etc/nginx/ssl/cert.pem\
                 -days 365\
                 -nodes\
                 -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=atricore.com"

                mkdir -p tmp/nginx_client_body

                # nginx still tries to read this directory even if error_log
                # directive is specifying another file :/
                mkdir -p var/log/nginx
              '';

                config = {

                  Cmd = [ "nginx" "-c" nginxConf ];
                  ExposedPorts = {
                    "${nginxPort}/tcp" = { };
                  };
                };
              };
          };

          # Shell with tools to work with the image
          devShells.default =
            pkgs.mkShell
              { buildInputs = with pkgs; [ vim gnumake ]; };
        });
}
