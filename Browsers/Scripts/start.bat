@echo off
ECHO These commands will enable tracing:
@echo on
logman create trace "winhttp_trace" -ow -o winhttp_trace.etl -p {B3A7698A-0C45-44DA-B73D-E181C9B5C8E6} 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman create trace "ieframe" -ow -o ieframe.etl -p "Microsoft-IEFRAME" 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman create trace "mshtml" -ow -o mshtml.etl -p "Microsoft-IE" 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman create trace "jscript" -ow -o jscript.etl -p "Microsoft-JScript" 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman create trace "urlmon" -ow -o urlmon.etl -p "Microsoft-Windows-URLMon" 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman create trace "winhttp" -ow -o winhttp.etl -p "Microsoft-Windows-WinHttp" 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman create trace "advanced_wininet" -ow -o advanced_wininet.etl -p {4E749B6A-667D-4C72-80EF-373EE3246B08} 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman create trace "wininet" -ow -o wininet.etl -p "Microsoft-Windows-WinINet" 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets

logman create trace "schannel" -ow -o schannel.etl -p {37D2C3CD-C5D4-4587-8531-4696C44244C8} 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman update trace "schannel" -p "Microsoft-Windows-Schannel-Events" 0xffffffffffffffff 0xff -ets
logman update trace "schannel" -p {44492B72-A8E2-4F20-B0AE-F1D437657C92} 0xffffffffffffffff 0xff -ets
logman update trace "schannel" -p {37D2C3CD-C5D4-4587-8531-4696C44244C8} 0xffffffffffffffff 0xff -ets
logman update trace "schannel" -p "Schannel" 0xffffffffffffffff 0xff -ets

logman create trace "dns" -ow -o dns.etl -p "Microsoft-Windows-DNS-Client" 0xffffffffffffffff 0xff -nb 16 16 -bs 1024 -mode Circular -f bincirc -max 4096 -ets
logman update trace "dns" -p {1540FF4C-3FD7-4BBA-9938-1D1BF31573A7} 0xffffffffffffffff 0xff -ets
logman update trace "dns" -p {9CA335ED-C0A6-4B4D-B084-9C9B5143AFF0} 0xffffffffffffffff 0xff -ets
logman update trace "dns" -p {367B7A5F-319C-4E40-A9F8-8856095389C7} 0xffffffffffffffff 0xff -ets
logman update trace "dns" -p {609151DD-04F5-4DA7-974C-FC6947EAA323} 0xffffffffffffffff 0xff -ets
logman update trace "dns" -p "Microsoft-Windows-Networking-ServiceDiscovery-Dnssd" 0xffffffffffffffff 0xff -ets

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
logman update trace "kerberos" -p {97A38277-13C0-4394-A0B2-2A70B465D64F} 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p "Microsoft-Windows-AuthenticationProvider" 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p {FACB33C4-4513-4C38-AD1E-57C1F6828FC0} 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p {60A7AB7A-BC57-43E9-B78A-A1D516577AE3} 0xffffffffffffffff 0xff -ets
logman update trace "kerberos" -p {1BBA8B19-7F31-43C0-9643-6E911F79A06B} 0xffffffffffffffff 0xff -ets

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

@echo off
echo
ECHO Reproduce your issue and enter any key to stop tracing
@echo on
pause
logman stop "ieframe" -ets
logman stop "schannel" -ets
logman stop "mshtml" -ets
logman stop "jscript" -ets
logman stop "urlmon" -ets
logman stop "winhttp" -ets
logman stop "advanced_wininet" -ets
logman stop "wininet" -ets
logman stop "winhttp_trace" -ets
logman stop "ntlm" -ets
logman stop "dns" -ets
logman stop "network" -ets
logman stop "kerberos" -ets