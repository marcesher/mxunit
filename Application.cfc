<cfcomponent>
	
	<cfset this.name = "mxunit">
	<cfset this.metricsEnabled = true>
	<cfset root = getDirectoryFromPath( getCurrentTemplatePath() )>
	<cffunction name="onApplicationStart">
		<cfscript>
        	        
			structDelete( server, "appJavaLoader" );
			server.mxunitMetricsJavaLoader = new mxunit.framework.javaloader.JavaLoader(loadPaths = [root & "/framework/javaloader/support/cfcdynamicproxy/lib/cfcdynamicproxy.jar"], loadColdFusionClassPath = true);
	
			//for convenience
			application.javaloader = server.mxunitMetricsJavaLoader;
			
			application.completionQueue = createObject("java", "java.util.concurrent.LinkedBlockingQueue").init( 100000 );

			application.executorThreadPool = createObject("java", "java.util.concurrent.Executors").newFixedThreadPool( 4 );
	
			application.completionService = createObject("java", "java.util.concurrent.ExecutorCompletionService").init(application.executorThreadPool, application.completionQueue);
	
			application.CFCDynamicProxy = application.javaloader.create("com.compoundtheory.coldfusion.cfc.CFCDynamicProxy");
			application.taskInterfaces = ["java.util.concurrent.Callable"];
			
			application._metricsdebuggingService = createObject("java", "coldfusion.server.ServiceFactory").getDebuggingService();
        </cfscript>


	</cffunction>
	
	<cffunction name="onRequestStart" output="false" access="public" returntype="any" hint="">    
    	<cfif structKeyExists(url, "reinit")>
			<cfset onApplicationStart()>
		</cfif>
    </cffunction>
	
	<cffunction name="onRequestEnd">
		
		<cfif this.metricsEnabled>
			<cflog text="saving metrics">
			<cfset var qEvents = application._metricsdebuggingService.getDebugger().getData()>
			<cfset var summary = "">
			<cfquery dbType="query" name="summary" debug="false">
				SELECT  template, Sum(endTime - startTime) AS totalExecutionTime, count(template) AS instances
				FROM qEvents
				WHERE type = 'Template'
				and parent not like '%ModelGlue%'
				and parent not like '%Coldspring%'
				and template not like '%EventContext.cfc'
				group by template
				order by totalExecutionTime DESC
	        </cfquery>
		
		
			<cfset var task = new MetricsParseTask(summary)>
			<cfset var proxy = application.CFCDynamicProxy.createInstance( task, application.taskInterfaces )>
	
			<cfset application.completionService.submit( proxy )>
			<cflog text="proxy submitted to the queue">
	
		
		</cfif>
	</cffunction>
	
	
	<cffunction name="createMetrics" output="false" access="public" returntype="array" hint="">
		<cfargument name="metricsQuery" type="query" required="true"/>
		
		<cfset var all = []>
		<cfloop query="metricsQuery">
			<cfset var result = parseTemplate(metricsQuery.template)>
			<cfset result.instances = metricsQuery.instances>
			<cfset result.totalExecutionTime = metricsQuery.totalExecutionTime>
			<cfset arrayAppend( all, result )>
		</cfloop>
		<cfreturn all>
	</cffunction>

	<!---<cfdump var="#data#">--->

	<cffunction name="parseTemplate" output="false" access="public" returntype="any" hint="">
    	<cfargument name="template" type="string" required="true"/>
		<cfset var result = {found = false, template = template, method="", args=""}>
		<cfset var templateAndMethod = reMatch("CFC\[ .*\]", template)>
		<cfif arrayLen(templateAndMethod) eq 1>
			<cfset var tmp = templateAndMethod[1]>
			<cfset var f = trim(replace(listFirst(tmp, "|" ), "CFC[", "", "one"))>
			<cfset var method = trim(replace(listLast(tmp, "|" ), ") ]", ")", "one"))>


			<cfset var args = reMatch("\(.*\)", method)[1]>
			<cfset args = mid( args,2, len(args)-2 )>
			<cfset method = listFirst(method, "(")>
			<cfset result = {found = true, template = f, method = method, args = args}>
		</cfif>
		<cfreturn result>
    </cffunction>
	
</cfcomponent>