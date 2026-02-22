{
  config,
  pkgs,
  lib,
  ...
}:
{
  options = {
    services.tango-controls = {
      enable = lib.mkEnableOption "tango-controls server";
      package = lib.mkPackageOption pkgs "tango-database" { };
      verbose = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to run the tango database in verbose mode";
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 10000;
        description = "Port to run tango on";
      };
      autoStart = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to auto-start tango as a dependency of multi-user.target";
      };
      database = {
        managed = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether the tango database is managed by the NixOS module";
        };
      };
    };
  };
  config =
    let
      cfg = config.services.tango-controls;
    in
    {
      services.mysql = lib.mkIf cfg.database.managed {
        enable = true;
        package = lib.mkDefault pkgs.mariadb;
        ensureUsers = [
          {
            name = "tango";
            ensurePermissions = {
              "tango.*" = "ALL PRIVILEGES";
            };
          }
        ];
        ensureDatabases = [ "tango" ];
      };
      # the service name needs to be tango to access the tango database via socket auth
      # TODO: fix
      systemd.services.tango = lib.mkIf cfg.enable {
        description = "tango database server";
        requires = lib.optionals cfg.database.managed [ "mysql.service" ];
        wantedBy = lib.optionals cfg.autoStart [ "multi-user.target" ];
        path = [ config.services.mysql.package ];
        serviceConfig = {
          # create the tango database on first start
          ExecStartPre = "${lib.getExe pkgs.python3} ${./tango_db_manager.py} -s '${cfg.package}/share/tango/db/create_db.sql'";
          ExecStart = "${cfg.package}/bin/Databaseds 2 -ORBendPoint giop:tcp::${toString cfg.port} ${lib.optionalString cfg.verbose "-v"}";
          DynamicUser = true;
        };
      };
    };
}
