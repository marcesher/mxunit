<cfcomponent>

	<cfset this.name = "mxunit">
	<cfset this.metricsEnabled = true>
	<cfset root = getDirectoryFromPath( getCurrentTemplatePath() )>

	<cffunction name="onApplicationStart">
		<cfscript>
			if( structKeyExists(application, "metricsCollector") ){
				application.metricsCollector.stop();
			}

			application.metricsPublisher = createObject("component", "cfmetrics.publishers.FilePublisher")
				.init("mxunit", root & "/cfmetrics_output/");
			application.metricsCollector = createObject("component", "cfmetrics.MetricsCollector").init(5, [application.metricsPublisher]).start();
			application.metricsCollector.setMinMillisToLog(2);
        </cfscript>
	</cffunction>

	<cffunction name="onRequestStart" output="false" access="public" returntype="any" hint="">
		<cfsetting showdebugoutput="false" >
    	<cfif structKeyExists(url, "reinit")>
			<cfset onApplicationStart()>
		</cfif>
    </cffunction>

	<cffunction name="onRequestEnd">

		<cfset application.metricsCollector.collect()>
	</cffunction>

</cfcomponent>