<h1>Bens Json Serializer For Wheels</h1>
<p>Swaps renderWith()'s use of serializeJson() with Ben Nadel's JsonSerializer.</p>
<p></p>
<h2>Defining Mappings</h2>
<p>Below, I've used several config files to define my mappings, which are called by an index file that initializes a serializer and uses those configs to define the mappings. This setup is not requried, but it simplifies the setup <i>imo</i>. If there is no serializer defined in params or application.wheels scope, a default one will be initialized for the serialization attempt.</p>
<pre><code>&lt;cfscript&gt;
    writeLog("Initializing serializer mappings...");

    include "./anys.cfm";
    include "./booleans.cfm";
    include "./dates.cfm";
    include "./floats.cfm";
    include "./integers.cfm";
    include "./strings.cfm";
    include "./excludes.cfm";
    
    serializer = initBenSerializerDefault();
    
    for (key in anys) serializer.asAny(key);
    for (key in booleans) serializer.asBoolean(key);
    for (key in dates) serializer.asDate(key);
    for (key in floats) serializer.asFloat(key);
    for (key in integers) serializer.asInteger(key);
    for (key in strings) serializer.asString(key);
    for (key in excludes) serializer.exclude(key);
    
    writeLog("Serializer mappings initialized.");
&lt;/cfscript&gt;
</code></pre>

