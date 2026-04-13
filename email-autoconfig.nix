{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.email-autoconfig;

  # Thunderbird autoconfig XML
  autoconfigXml = pkgs.writeText "autoconfig.xml" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <clientConfig version="1.1">
      <emailProvider id="${cfg.domain}">
        <domain>${cfg.domain}</domain>
        <displayName>${cfg.displayName}</displayName>
        <displayShortName>${cfg.displayShortName}</displayShortName>

        <incomingServer type="imap">
          <hostname>${cfg.mailDomain}</hostname>
          <port>${toString cfg.imap.port}</port>
          <socketType>${cfg.imap.socketType}</socketType>
          <authentication>${cfg.imap.authentication}</authentication>
          <username>%EMAILADDRESS%</username>
        </incomingServer>

        <outgoingServer type="smtp">
          <hostname>${cfg.mailDomain}</hostname>
          <port>${toString cfg.smtp.port}</port>
          <socketType>${cfg.smtp.socketType}</socketType>
          <authentication>${cfg.smtp.authentication}</authentication>
          <username>%EMAILADDRESS%</username>
        </outgoingServer>
      </emailProvider>
    </clientConfig>
  '';

  # Outlook Autodiscover XML
  autodiscoverXml = pkgs.writeText "autodiscover.xml" ''
    <?xml version="1.0" encoding="utf-8"?>
    <Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006">
      <Response xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a">
        <Account>
          <AccountType>email</AccountType>
          <Action>settings</Action>
          <Protocol>
            <Type>IMAP</Type>
            <Server>${cfg.mailDomain}</Server>
            <Port>${toString cfg.imap.port}</Port>
            <LoginName/>
            <DomainRequired>off</DomainRequired>
            <SPA>off</SPA>
            <SSL>${if cfg.imap.socketType == "SSL" then "on" else "off"}</SSL>
            <AuthRequired>on</AuthRequired>
          </Protocol>
          <Protocol>
            <Type>SMTP</Type>
            <Server>${cfg.mailDomain}</Server>
            <Port>${toString cfg.smtp.port}</Port>
            <LoginName/>
            <DomainRequired>off</DomainRequired>
            <SPA>off</SPA>
            <SSL>${if cfg.smtp.socketType == "SSL" then "on" else "off"}</SSL>
            <AuthRequired>on</AuthRequired>
            <UsePOPAuth>off</UsePOPAuth>
            <SMTPLast>off</SMTPLast>
          </Protocol>
        </Account>
      </Response>
    </Autodiscover>
  '';

  # Apple Mail .mobileconfig
  mobileconfigContent = pkgs.writeText "profile.mobileconfig" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
      "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>PayloadContent</key>
      <array>
        <dict>
          <key>EmailAccountDescription</key>
          <string>${cfg.displayName}</string>
          <key>EmailAccountName</key>
          <string>${cfg.displayShortName}</string>
          <key>EmailAccountType</key>
          <string>EmailTypeIMAP</string>
          <key>EmailAddress</key>
          <string/>
          <key>IncomingMailServerHostName</key>
          <string>${cfg.mailDomain}</string>
          <key>IncomingMailServerPortNumber</key>
          <integer>${toString cfg.imap.port}</integer>
          <key>IncomingMailServerUseSSL</key>
          <${boolToString (cfg.imap.socketType == "SSL")}/>
          <key>IncomingMailServerUsername</key>
          <string/>
          <key>OutgoingMailServerHostName</key>
          <string>${cfg.mailDomain}</string>
          <key>OutgoingMailServerPortNumber</key>
          <integer>${toString cfg.smtp.port}</integer>
          <key>OutgoingMailServerUseSSL</key>
          <${boolToString (cfg.smtp.socketType == "SSL")}/>
          <key>OutgoingMailServerUsername</key>
          <string/>
          <key>PayloadDescription</key>
          <string>Email account settings</string>
          <key>PayloadDisplayName</key>
          <string>${cfg.displayName}</string>
          <key>PayloadIdentifier</key>
          <string>com.${cfg.domain}.mail</string>
          <key>PayloadType</key>
          <string>com.apple.mail.managed</string>
          <key>PayloadUUID</key>
          <string>${cfg.mobileconfig.mailUuid}</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
          <key>SMIMEEnabled</key>
          <false/>
        </dict>

      </array>
      <key>PayloadDescription</key>
      <string>${cfg.mobileconfig.description}</string>
      <key>PayloadDisplayName</key>
      <string>${cfg.displayName}</string>
      <key>PayloadIdentifier</key>
      <string>com.${cfg.domain}.mail.profile</string>
      <key>PayloadOrganization</key>
      <string>${cfg.mobileconfig.organization}</string>
      <key>PayloadRemovalDisallowed</key>
      <false/>
      <key>PayloadType</key>
      <string>Configuration</string>
      <key>PayloadUUID</key>
      <string>${cfg.mobileconfig.profileUuid}</string>
      <key>PayloadVersion</key>
      <integer>1</integer>
    </dict>
    </plist>
  '';

  # Static webroot
  mailConfigRoot = pkgs.runCommand "mail-config-root" { } ''
    mkdir -p $out/mail
    mkdir -p $out/Autodiscover
    mkdir -p $out/autodiscover

    cp ${autoconfigXml}       $out/mail/config-v1.1.xml
    cp ${autodiscoverXml}     $out/Autodiscover/Autodiscover.xml
    cp ${autodiscoverXml}     $out/autodiscover/autodiscover.xml
    cp ${mobileconfigContent} $out/mobileconfig
  '';

in
{
  options.email-autoconfig = {
    enable = mkEnableOption "email autoconfiguration service";

    domain = mkOption {
      type = types.str;
      example = "example.com";
      description = "Base domain for email service";
    };

    mailDomain = mkOption {
      type = types.str;
      default = "mail.${cfg.domain}";
      description = "Hostname of the mail server";
    };

    displayName = mkOption {
      type = types.str;
      default = "${cfg.domain} Email";
      description = "Display name for the email service";
    };

    displayShortName = mkOption {
      type = types.str;
      default = cfg.domain;
      description = "Short display name for the email service";
    };

    imap = {
      port = mkOption {
        type = types.port;
        default = 993;
        description = "IMAP port";
      };

      socketType = mkOption {
        type = types.enum [ "SSL" "STARTTLS" "plain" ];
        default = "SSL";
        description = "IMAP connection security type";
      };

      authentication = mkOption {
        type = types.str;
        default = "password-cleartext";
        description = "IMAP authentication method";
      };
    };

    smtp = {
      port = mkOption {
        type = types.port;
        default = 465;
        description = "SMTP port";
      };

      socketType = mkOption {
        type = types.enum [ "SSL" "STARTTLS" "plain" ];
        default = "SSL";
        description = "SMTP connection security type";
      };

      authentication = mkOption {
        type = types.str;
        default = "password-cleartext";
        description = "SMTP authentication method";
      };
    };

    mobileconfig = {
      description = mkOption {
        type = types.str;
        default = "Configures email for ${cfg.domain}";
        description = "Description shown in iOS/macOS profile";
      };

      domain = mkOption {
        type = types.str;
        default = cfg.mailDomain;
        description = "Domain name for the mobileconfig profile";
      };

      organization = mkOption {
        type = types.str;
        default = cfg.domain;
        description = "Organization name shown in iOS/macOS profile";
      };

      profileUuid = mkOption {
        type = types.str;
        default = "B2C3D4E5-F6A7-8901-BCDE-F12345678901";
        description = "UUID for the profile payload";
      };

      mailUuid = mkOption {
        type = types.str;
        default = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890";
        description = "UUID for the mail payload";
      };
    };
  };

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;

      virtualHosts = {
        # autoconfig.domain — Thunderbird
        "autoconfig.${cfg.domain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          root = "${mailConfigRoot}";

          locations."/mail/config-v1.1.xml" = {
            extraConfig = ''
              default_type application/xml;
              add_header Content-Disposition 'inline; filename="config-v1.1.xml"';
              add_header Access-Control-Allow-Origin "*";
            '';
          };
        };

        # autodiscover.domain — Outlook
        "autodiscover.${cfg.domain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          root = "${mailConfigRoot}";

          locations."/Autodiscover/Autodiscover.xml" = {
            extraConfig = ''
              default_type application/xml;
              add_header Access-Control-Allow-Origin "*";
            '';
          };

          # Case-insensitive catch-all — Outlook varies capitalisation
          locations."~* ^/autodiscover/autodiscover\\.xml$" = {
            extraConfig = ''
              default_type application/xml;
              add_header Access-Control-Allow-Origin "*";
            '';
          };
        };

        # mail.domain — Apple mobileconfig
        "${cfg.mobileconfig.domain}" = {
          enableACME = true;
          forceSSL = true;
          acmeRoot = null;
          root = "${mailConfigRoot}";

          locations."/mobileconfig" = {
            extraConfig = ''
              default_type application/x-apple-aspen-config;
              add_header Content-Disposition 'attachment; filename="mail.mobileconfig"';
            '';
          };
        };
      };
    };
  };
}
