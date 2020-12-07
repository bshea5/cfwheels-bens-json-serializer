component hint = "Modify core.renderWith() to use Ben Nadel's Json Serializer instead of CF engine serializer."
output = "false"
mixin = "global" {

    public function init() {
        this.version = "2.1";

        return this;
    }

    /**
	 * Initialize Ben Nadel's JsonSerializer.
	 */
	public function initBenSerializer() {
		return CreateObject( "component", "JsonSerializer" ).init();
    }
    
    /**
	 * Initialize Ben Nadel's JsonSerializer with default mappings. 
     * Default mappings include:
     * * Fields typically found in a CFWheels application.
     * * Columns defined as date 'like' as date.
     * * Foreign Key columns as integers.
	 */
    public function initBenSerializerDefault() {
        var serializer = initBenSerializer();
        var dates = $getDateCols();
        var integers = [
            "status",
            "maxrows",
            "perpage",
            "endrow",
            "startrow",
            "totalrecords",
            "totalpages",
            "currentpage",
            "id"
        ];
        integers.append($getFKCols(), true);   

        for (var i in integers) serializer.asInteger(i);
        for (var d in dates) serializer.asDate(d);

        return serializer;
    }

    /**
     * Serialize given data. Use serializer if one is persisted in the app or controller.
     * Else initialize one for the action.
     * 
     * Reconmended initializing and defining mappings in onapplicationstart.
     * 
     * @data Data to format
     */
    // Leave it exposed in case we need in application.
    public function benSerializeJSON(required any data) {
        var serializer = params?.serializer
            ?: application?.wheels?.serializer
            ?: initBenSerializerDefault();

        return serializer.serialize(arguments.data);
    }

    /**
     * OVERRIDEN: Replaced use of CF engine's serializeJSON with Ben Nadel's JsonSerializer.
     * 
     * Instructs the controller to render the data passed in to the format that is requested.
     * If the format requested is `json` or `xml`, CFWheels will transform the data into that format automatically.
     * For other formats (or to override the automatic formatting), you can also create a view template in this format: `nameofaction.xml.cfm`, `nameofaction.json.cfm`, `nameofaction.pdf.cfm`, etc.
     *
     * [section: Controller]
     * [category: Provides Functions]
     *
     * @data Data to format and render.
     * @controller [see:renderView].
     * @action [see:renderView].
     * @template [see:renderView].
     * @layout [see:renderView].
     * @cache [see:renderView].
     * @returnAs [see:renderView].
     * @hideDebugInformation [see:renderView].
     * @status Force request to return with specific HTTP status code.
     */
    public any function renderWith(
        required any data,
        string controller=variables.params.controller,
        string action=variables.params.action,
        string template="",
        any layout,
        any cache="",
        string returnAs="",
        boolean hideDebugInformation=false,
        any status="200"
    ) {
        $args(name="renderWith", args=arguments);
        local.contentType = $requestContentType();
        local.acceptableFormats = $acceptableFormats(action=arguments.action);

        // Default to html if the content type found is not acceptable.
        if (!ListFindNoCase(local.acceptableFormats, local.contentType)) {
            local.contentType = "html";
        }

        if (local.contentType == "html") {

            // Call render page when we are just rendering html.
            StructDelete(arguments, "data");
            local.rv = renderView(argumentCollection=arguments);

        } else {
            local.templateName = $generateRenderWithTemplatePath(argumentCollection=arguments, contentType=local.contentType);
            local.templatePathExists = $formatTemplatePathExists($name=local.templateName);
            if (local.templatePathExists) {
                local.content = renderView(argumentCollection=arguments, template=local.templateName, returnAs="string", layout=false, hideDebugInformation=true);
            }

            // Throw an error if we rendered a pdf template and we got here, the cfdocument call should have stopped processing.
            if (local.contentType == "pdf" && $get("showErrorInformation") && local.templatePathExists) {
                Throw(
                    type="Wheels.PdfRenderingError",
                    message="When rendering the a PDF file, don't specify the filename attribute. This will stream the PDF straight to the browser."
                );
            }

            // Throw an error if we do not have a template to render the content type that we do not have defaults for.
            if (!ListFindNoCase("json,xml", local.contentType) && !StructKeyExists(local, "content") && $get("showErrorInformation")) {
                Throw(
                    type="Wheels.RenderingError",
                    message="To render the #local.contentType# content type, create the template `#local.templateName#.cfm` for the #arguments.controller# controller."
                );
            }

            // Set our header based on our mime type.
            local.formats = $get("formats");
            local.value = local.formats[local.contentType] & "; charset=utf-8";
            $header(name="content-type", value=local.value, charset="utf-8");

            // If custom statuscode passed in, then set appropriate header.
            // Status may be a numeric value such as 404, or a text value such as "Forbidden".
            if (StructKeyExists(arguments, "status")) {
                local.status=arguments.status;
                if (IsNumeric(local.status)) {
                    local.statusCode=local.status;
                    local.statusText=$returnStatusText(local.status);
                } else {
                    // Try for statuscode;
                    local.statusCode=$returnStatusCode(local.status);
                    local.statusText=local.status;
                }
                $header(statusCode=local.statusCode, statusText=local.statusText);
            }

            // If we do not have the local.content variable and we are not rendering html then try to create it.
            if (!StructKeyExists(local, "content")) {
                switch (local.contentType) {
                    case "json":
                        local.namedArgs = {};

                        if (StructCount(arguments) > 8) {
                            local.namedArgs = $namedArguments(argumentCollection=arguments, $defined="data,controller,action,template,layout,cache,returnAs,hideDebugInformation");
                        }
                        for (local.key in local.namedArgs) {
                            if (local.namedArgs[local.key] == "string") {
                                if (IsArray(arguments.data)) {
                                    local.iEnd = ArrayLen(arguments.data);
                                    for (local.i = 1; local.i <= local.iEnd; local.i++) {

                                        // Force to string by wrapping in non printable character (that we later remove again).
                                        arguments.data[local.i][local.key] = Chr(7) & arguments.data[local.i][local.key] & Chr(7);
                                    }
                                }
                            }
                        }
                        // ====================================================
                        // Replace this line & use another serializer
                        // local.content = SerializeJSON(arguments.data);
                        local.content = benSerializeJSON(arguments.data);
                        // ====================================================

                        if (Find(Chr(7), local.content)) {
                            local.content = Replace(local.content, Chr(7), "", "all");
                        }
                        for (local.key in local.namedArgs) {
                            if (local.namedArgs[local.key] == "integer") {

                                // Force to integer by removing the .0 part of the number.
                                local.content = REReplaceNoCase(local.content, '([{|,]"' & local.key & '":[0-9]*)\.0([}|,"])', "\1\2", "all");

                            }
                        }
                        break;
                    case "xml":
                        local.content = $toXml(arguments.data);
                        break;
                }
            }

            // If the developer passed in returnAs="string" then return the generated content to them.
            if (arguments.returnAs == "string") {
                local.rv = local.content;
            } else {
                renderText(local.content);
            }

        }
        if (StructKeyExists(local,"rv")) {
            return local.rv;
        }
    }

    public array function $getDateCols() {
        var dateColsQry = queryExecute("
            select distinct
                c.name as column_name
            from sys.columns c
            join sys.tables t
                on t.object_id = c.object_id
            where type_name(user_type_id) in ('date', 'datetimeoffset', 
                'datetime2', 'smalldatetime', 'datetime', 'time')
        ");

        return valueArray(dateColsQry, "column_name");
    }

    public array function $getFKCols() {
        var fkColsQry = queryExecute("
            SELECT DISTINCT KF.COLUMN_NAME column_name
            FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC
            JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KF ON RC.CONSTRAINT_NAME = KF.CONSTRAINT_NAME
            JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KP ON RC.UNIQUE_CONSTRAINT_NAME = KP.CONSTRAINT_NAME
            WHERE KP.COLUMN_NAME = 'id'
        ");

        return valueArray(fkColsQry, "column_name");
    }
}