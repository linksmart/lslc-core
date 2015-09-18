# CHANGELOG

* 0.2.0
    - Migration from Godepts to GB vendor
    - Updated github.com/oleksandr/bonjour package and its usage:
      + New method for shutdown
    - Updated github.com/gorilla/mux package and it usage:
      + New RegEx format for variable path depths
    - Changed code.google.com/p/go-uuid/uuid to github.com/pborman/uuid 
      + Google Code is no longer go gettable
    - Replaced PublicAddr with PublichEndpoint:
      + Allows to use custom <protocol>://<addr>:<port> for local endpoints when publishing to catalogs etc. E.g., can be used together with reverse proxy.
