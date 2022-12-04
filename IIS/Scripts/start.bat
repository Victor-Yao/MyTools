@echo off
ECHO These commands will enable tracing:
@echo on
logman create trace "iis" -ow -o iis.etl -p "Microsoft-Windows-IIS" 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman create trace "winhttp_trace" -ow -o winhttp_trace.etl -p {B3A7698A-0C45-44DA-B73D-E181C9B5C8E6} 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman create trace "winhttp" -ow -o winhttp.etl -p "Microsoft-Windows-WinHttp" 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets

logman create trace "schannel" -ow -o schannel.etl -p {37D2C3CD-C5D4-4587-8531-4696C44244C8} 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman update trace "schannel" -p "Microsoft-Windows-Schannel-Events" 0xffffffffffffffff 0xff -ets
logman update trace "schannel" -p {44492B72-A8E2-4F20-B0AE-F1D437657C92} 0xffffffffffffffff 0xff -ets
logman update trace "schannel" -p {37D2C3CD-C5D4-4587-8531-4696C44244C8} 0xffffffffffffffff 0xff -ets
logman update trace "schannel" -p "Schannel" 0xffffffffffffffff 0xff -ets

logman create trace "network" -ow -o network.etl -p "Microsoft-Windows-Winsock-AFD" 0xffffffffffffffff 0x4 -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman update trace "network" -p "Microsoft-Windows-TCPIP" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-WFP" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-Windows Firewall With Advanced Security" 0xffffffffffffffff 0x5 -ets
logman update trace "network" -p "Microsoft-Windows-Dhcp-Client" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-DHCPv6-Client" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-Dhcp-Nap-Enforcement-Client" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-NDIS" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-WWAN-SVC-EVENTS" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-WWAN-UI-EVENTS" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-WWAN-MM-EVENTS" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-WWAN-NDISUIO-EVENTS" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-NWiFi" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-VWiFi" 0xffffffffffffffff 0x5 -ets
logman update trace "network" -p "Microsoft-Windows-L2NACP" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-WLAN-AutoConfig" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-EapHost" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-OneX" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-Wired-AutoConfig" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-Iphlpsvc-Trace" 0x800000000000000a 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-WebIO" 0xffffffffffffffff 0x5 -ets
logman update trace "network" -p "Microsoft-Windows-BranchCacheEventProvider" 0xffffffffffffffff 0x5 -ets
logman update trace "network" -p "Microsoft-Windows-BranchCacheClientEventProvider" 0xffffffffffffffff 0x5 -ets
logman update trace "network" -p "Microsoft-Windows-NCSI" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-NlaSvc" 0xffffffffffffffff 0x4 -ets
logman update trace "network" -p "Microsoft-Windows-NetworkProfile" 0xffffffffffffffff 0x4 -ets

logman create trace "ntlm" -ow -o ntlm.etl -p "Microsoft-Windows-NTLM" 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman update trace "ntlm" -p "Microsoft-Windows-AuthenticationProvider" 0xffffffffffffffff 0xff -ets
logman update trace "ntlm" -p {AC69AE5B-5B21-405F-8266-4424944A43E9} 0xffffffffffffffff 0xff -ets
logman update trace "ntlm" -p {5BBB6C18-AA45-49B1-A15F-085F7ED0AA90} 0xffffffffffffffff 0xff -ets
logman update trace "ntlm" -p {C92CF544-91B3-4DC0-8E11-C580339A0BF8} 0xffffffffffffffff 0xff -ets

logman create trace "kerberos" -ow -o kerberos.etl -p {6B510852-3583-4E2D-AFFE-A67F9F223438} 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman update trace "kerberos" -p {BBA3ADD2-C229-4CDB-AE2B-57EB6966B0C4} 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p "Microsoft-Windows-Security-Kerberos" 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p {24DB8964-E6BC-11D1-916A-0000F8045B04} 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p "Microsoft-Windows-Kerberos-Key-Distribution-Center" 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p "Microsoft-Windows-KDCPW-WPP" 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p "Microsoft-Windows-KPSSVC-WPP" 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p {6C51FAD2-BA7C-49B8-BF53-E60085C13D92} 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p "Microsoft-Windows-AuthenticationProvider" 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p {97A38277-13C0-4394-A0B2-2A70B465D64F} 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p {FACB33C4-4513-4C38-AD1E-57C1F6828FC0} 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p {60A7AB7A-BC57-43E9-B78A-A1D516577AE3} 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p {1BBA8B19-7F31-43C0-9643-6E911F79A06B} 0xffffffffffffffff 0xff -ets

logman create trace "winlogon" -ow -o winlogon.etl -p "Microsoft-Windows-Winlogon" 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman update trace "winlogon" -p {D451642C-63A6-11D7-9720-00B0D03E0347} 0xffffffffffffffff 0xff -ets
logman update trace "winlogon" -p {D9391D66-EE23-4568-B3FE-876580B31530} 0xffffffffffffffff 0xff -ets
logman update trace "winlogon" -p {63665931-A4EE-47B3-874D-5155A5CFB415} 0xffffffffffffffff 0xff -ets
logman update trace "winlogon" -p {855ED56A-6120-4564-B083-34CB9D598A22} 0xffffffffffffffff 0xff -ets
logman update trace "winlogon" -p {D138F9A7-0013-46A6-ADCC-A3CE6C46525F} 0xffffffffffffffff 0xff -ets
logman update trace "winlogon" -p {C127C1A8-6CEB-11DA-8BDE-F66BAD1E3F3A} 0xffffffffffffffff 0xff -ets
logman update trace "winlogon" -p {BFA655DC-6C51-11DA-8BDE-F66BAD1E3F3A} 0xffffffffffffffff 0xff -ets
logman update trace "winlogon" -p {301779E2-227D-4FAF-AD44-664501302D03} 0xffffffffffffffff 0xff -ets
logman update trace "winlogon" -p {19D78D7D-476C-47B6-A484-285D1290A1F3} 0xffffffffffffffff 0xff -ets
logman update trace "winlogon" -p {A789EFEB-FC8A-4C55-8301-C2D443B933C0} 0xffffffffffffffff 0xff -ets
logman update trace "winlogon" -p {C2BA06E2-F7CE-44AA-9E7E-62652CDEFE97} 0xffffffffffffffff 0xff -ets

logman create trace "dns" -ow -o dns.etl -p "Microsoft-Windows-DNS-Client" 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman update trace "dns" -p {1540FF4C-3FD7-4BBA-9938-1D1BF31573A7} 0xffffffffffffffff 0xff -ets
logman update trace "dns" -p {9CA335ED-C0A6-4B4D-B084-9C9B5143AFF0} 0xffffffffffffffff 0xff -ets
logman update trace "dns" -p {367B7A5F-319C-4E40-A9F8-8856095389C7} 0xffffffffffffffff 0xff -ets
logman update trace "dns" -p {609151DD-04F5-4DA7-974C-FC6947EAA323} 0xffffffffffffffff 0xff -ets
logman update trace "dns" -p "Microsoft-Windows-Networking-ServiceDiscovery-Dnssd" 0xffffffffffffffff 0xff -ets

logman create trace "iis_all" -ow -o iis_all.etl -p "Microsoft-Windows-IIS-Configuration" 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman update trace "iis_all" -p "Microsoft-Windows-IIS-IisMetabaseAudit" 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p "Microsoft-Windows-IIS-IISReset" 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p "Microsoft-Windows-IIS-W3SVC-WP" 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p "Microsoft-Windows-IIS-W3SVC-PerfCounters" 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p "Microsoft-Windows-WAS-ListenerAdapter" 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p "Microsoft-Windows-WAS" 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p "Microsoft-Windows-IIS-W3SVC" 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p "Microsoft-Windows-IIS-WMSVC" 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p "Microsoft-Windows-IIS-APPHOSTSVC" 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p "Microsoft-Windows-W3LOGSVC" 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p "Microsoft-Windows-IIS-Logging" 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p {3A2A4E84-4C21-4981-AE10-3FDA0D9B0F83} 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p {D55D3BC9-CBA9-44DF-827E-132D3A4596C2} 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p {A1C2040E-8840-4C31-BA11-9871031A19EA} 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p {DC1271C2-A0AF-400F-850C-4E42FE16BE1C} 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p "Microsoft-Windows-IIS-CentralCertificateProvider" 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p {06B94D9A-B15E-456E-A4EF-37C984A2CB4B} 0xffffffffffffffff 0xff -ets
logman update trace "iis_all" -p "Microsoft-Windows-Application Server-System Services IIS Manager" 0xffffffffffffffff 0xff -ets

logman create trace "ftp" -ow -o ftp_all.etl -p "Microsoft-Windows-IIS-FTP" 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman update trace "ftp" -p "Microsoft-Windows-FTPSVC" 0xffffffffffffffff 0xff -ets
logman update trace "ftp" -p {08AB3B7F-DE13-445E-8331-745FD7183ECB} 0xffffffffffffffff 0xff -ets

logman create trace "httpsys" -ow -o httpsys.etl -p {DD5EF90A-6398-47A4-AD34-4DCECDEF795F} 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman update trace "httpsys" -p {B1945E15-4933-460F-8103-AA611DDB663A} 0xffffffffffffffff 0xff -ets
logman update trace "httpsys" -p {20F61733-57F1-4127-9F48-4AB7A9308AE2} 0xffffffffffffffff 0xff -ets
logman update trace "httpsys" -p "Microsoft-Windows-HttpLog" 0xffffffffffffffff 0xff -ets
logman update trace "httpsys" -p "Microsoft-Windows-HttpService" 0xffffffffffffffff 0xff -ets
logman update trace "httpsys" -p "Microsoft-Windows-HttpEvent" 0xffffffffffffffff 0xff -ets
logman update trace "httpsys" -p "Microsoft-Windows-Http-SQM-Provider" 0xffffffffffffffff 0xff -ets

@echo off
echo
ECHO Reproduce your issue and enter any key to stop tracing
@echo on
pause
logman stop "iis" -ets
logman stop "schannel" -ets
logman stop "network" -ets
logman stop "ntlm" -ets
logman stop "kerberos" -ets
logman stop "dns" -ets
logman stop "httpsys" -ets
logman stop "iis_all" -ets
logman stop "ftp" -ets
logman stop "winhttp_trace" -ets
logman stop "winhttp" -ets
logman stop "winlogon" -ets