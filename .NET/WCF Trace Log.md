# enable WCF Trace log

- Copy and paste below configuration to the WCF configuration file of WCF client and WCF server.
- Make sure the directory of value of initializeData is existed. The directory is **c:\logs** in the example.

```bash
    <configuration>
        <system.diagnostics>
            <sources>
                <source propagateActivity="true" name="System.ServiceModel" switchValue="Verbose,ActivityTracing">
                    <listeners>
                        <add type="System.Diagnostics.DefaultTraceListener" name="Default">
                            <filter type="" />
                        </add>
                        <add name="xml">
                            <filter type="" />
                        </add>
                    </listeners>
                </source>
                <source name="System.ServiceModel.MessageLogging">
                    <listeners>
                        <add name="xml"/>
                    </listeners>
                </source>
                <source name="System.Net">
                    <listeners>
                        <add name="System.Net"/>
                    </listeners>
                </source>
                <source name="System.Net.HttpListener">
                    <listeners>
                        <add name="System.Net"/>
                    </listeners>
                </source>
                <source name="System.Net.Sockets">
                    <listeners>
                        <add name="System.Net"/>
                    </listeners>
                </source>
                <source name="System.Net.Cache">
                    <listeners>
                        <add name="System.Net"/>
                    </listeners>
                </source>
            </sources>
            <sharedListeners>
                <add initializeData="c:\logs\tracelog.svclog" type="System.Diagnostics.XmlWriterTraceListener, System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" name="xml" traceOutputOptions="LogicalOperationStack, DateTime, Timestamp, ProcessId, ThreadId, Callstack">
                    <filter type="" />
                </add>
                <add name="System.Net" type="System.Diagnostics.TextWriterTraceListener" initializeData="c:\logs\SNtrace.log" traceOutputOptions = "DateTime" />
            </sharedListeners>
            <trace autoflush="true" />
            <switches>
                <add name="System.Net" value="Verbose" />
                <add name="System.Net.Sockets" value="Verbose" />
                <add name="System.Net.Cache" value="Verbose" />
                <add name="System.Net.HttpListener" value="Verbose" />
            </switches>
        </system.diagnostics>
    </configuration>
```