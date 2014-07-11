component {
	
    public any function init(fw){
        variables.fw = arguments.fw;
        
        return this;
    }

	public any function getFile(required struct config, required string file){
		var timestamp = GetHTTPTimeString(Now());
		var signature = "";
		var cfhttp = {};

        if (structkeyexists(arguments.config,"basePath"))
            arguments.file = arguments.config.basePath & arguments.file;

        arguments.signature = getSignature(config=arguments.config,date=timestamp,key=arguments.file);

		http url="#arguments.config.bucket#.s3.amazonaws.com#arguments.file#" {
			httpparam type="header" name="Date" value="#timestamp#";
			httpparam type="header" name="Authorization" value="AWS #arguments.config.accessKeyId#:#hmac_sha1(arguments.signature,arguments.config.awsSecretKey)#";
		}

		throwResponseError(cfhttp.statuscode, cfhttp.filecontent, arguments);

		return cfhttp.filecontent;
	}
	
	public void function putFile(required struct config, required string file, required any data){
		var stMeta = getMeta(config=arguments.config,file=arguments.file);
		var i = 0;
		var sortedAMZ = "";
		var amz = "";
		var signature = "";
		var timestamp = GetHTTPTimeString(Now());
		var cfhttp = "";
		var results = "";
		var path = "";
		var stDetail = structNew();

		arguments["stHeaders"] = structnew();
		arguments["stAMZHeaders"] = structnew();

        if (structkeyexists(arguments.config,"basePath"))
            arguments.file = arguments.config.basePath & arguments.file;

		if (arguments.config.security eq "public"){
			arguments.stAMZHeaders["x-amz-grant-read"] = 'uri="http://acs.amazonaws.com/groups/global/AllUsers"';
		}

		// add content type
		arguments.stHeaders["content-type"] = stMeta.content_type;

		// cache control
		if (structkeyexists(stMeta,"cache_control"))
			arguments.stHeaders["cache-control"] = stMeta.cache_control;

		// create signature
        arguments.signature = getSignature(arguments.config,"PUT","",arguments.stHeaders['content-type'],timestamp,arguments.stAMZHeaders,arguments.file);

		// REST call
		http method="PUT" url="https://#arguments.config.bucket#.s3.amazonaws.com#arguments.file#" charset="utf-8" result="cfhttp" timeout="1800"{
			// Amazon Global Headers
			httpparam type="header" name="Date" value="#timestamp#";
			httpparam type="header" name="Authorization" value="AWS #arguments.config.accessKeyId#:#hmac_sha1(arguments.signature,arguments.config.awsSecretKey)#";
			
			// Headers
			for (var i in arguments.stHeaders){
				httpparam type="header" name="#i#" value="#arguments.stHeaders[i]#";
			}

			// AMZ Headers
			for (var i in arguments.stAMZHeaders){
				httpparam type="header" name="#i#" value="#arguments.stAMZHeaders[i]#";
			}

			// Body
			if (fileexists(arguments.data))
				httpparam type="body" value="#fileReadBinary(arguments.data)#";
			else
				httpparam type="body" value="#arguments.data#";
		}

		throwResponseError(cfhttp.statuscode, cfhttp.filecontent, arguments);
	}


	public string function hmac_sha256(required string signMessage, required string signKey){
		return toBase64(LCase(hmac(arguments.signMessage, arguments.signKey, 'HmacSHA256')));
	}

	public string function hmac_sha1(required string signMessage, required string signKey){
		var jMsg = JavaCast("string",arguments.signMessage).getBytes("iso-8859-1");
		var jKey = JavaCast("string",arguments.signKey).getBytes("iso-8859-1");
		var key = createObject("java","javax.crypto.spec.SecretKeySpec");
		var mac = createObject("java","javax.crypto.Mac");

		key = key.init(jKey,"HmacSHA1");
		mac = mac.getInstance(key.getAlgorithm());
		mac.init(key);
		mac.update(jMsg);

		return toBase64(mac.doFinal());
	}

	public string function getSignature(required struct config, string verb="GET", string contentMD5="", string contentType="", string date=GetHTTPTimeString(Now()), struct amz={}, string key){
		var signature = arguments.verb & chr(10) & arguments.contentMD5 & chr(10) & arguments.contentType & chr(10) & arguments.date;
		var amzHeaders = listsort(lcase(structkeylist(arguments.amz)),"textnocase");
		var i = 0;
		
		for (i=1; i<=listlen(amzHeaders); i++){
			signature = listappend(signature,listgetat(amzHeaders,i) & ":" & trim(replace(arguments.amz[listgetat(amzHeaders,i)],chr(10),"","ALL")),chr(10));
		}

		signature = listappend(signature,"/" & arguments.config.bucket & replacelist(urlencodedformat(arguments.key),"%2F,%2D,%2E,%5F","/,-,.,_"),chr(10));

		return signature;
	}

	public void function throwResponseError(required string statuscode, required string response,struct details={}){
		var results = "";

		// check XML parsing
		if (isXML(arguments.response)){
			results = XMLParse(arguments.response);

			// check for errors
			if (structkeyexists(results,"error")){
				arguments.details.response = convertXmlToStruct(arguments.response,structnew());

				throw(type="s3error",message="Error accessing S3 API: #results.error.message.XMLText#",detail=serializeJSON(arguments.details));
			}
		}
		elseif (NOT listFindNoCase("200,204",listfirst(arguments.statuscode," "))){
			arguments.details.response = arguments.response;
			throw(type="http.#arguments.statuscode#",message="Error accessing S3 API: #arguments.statuscode#",detail=serializeJSON(arguments.details));
		}
	}

	public struct function getMeta(required struct config, required string file){
		var stResult = {};

		if (not isdefined("stResult.content_type")){
			switch(lcase(listlast(arguments.file,"."))){
				case "jpg":
				case "jpeg":
					stResult["content_type"] = "image/jpeg";
					break;
				case "json":
					stResult["content_type"] = "application/json";
					break;
				case "js":
					stResult["content_type"] = "text/javascript";
					break;
				default:
					stResult["content_type"] = getPageContext().getServletContext().getMimeType(arguments.file);
					break;
			}
		}

		// browser cache time
		if (structkeyexists(arguments.config,"maxAge")){
			param name="stResult.cache_control" default="";
			stResult.cache_control = rereplace(listappend(stResult.cache_control,"max-age=#arguments.config.maxAge#"),",([^ ])",", \1","ALL");
		}

		// proxy cache time
		if (structkeyexists(arguments.config,"sMaxAge")){
			param name="stResult.cache_control" default="";
			stResult.cache_control = rereplace(listappend(stResult.cache_control,"s-maxage=#arguments.config.maxAge#"),",([^ ])",", \1","ALL");
		}

		return stResult;
	}

	public struct function convertXmlToStruct(required string xmlNode, required struct str){
		// Setup local variables for recurse:
		var i = 0;
		var axml = arguments.xmlNode;
		var astr = arguments.str;
		var n = "";
		var tmpContainer = "";

		axml = XmlSearch(XmlParse(arguments.xmlNode),"/node()");
		axml = axml[1];
		// For each children of context node:
		for (i=1; i<=arrayLen(axml.XmlChildren); i++){
			// Read XML node name without namespace:
			n = replace(axml.XmlChildren[i].XmlName, axml.XmlChildren[i].XmlNsPrefix&":", "");
			// If key with that name exists within output struct ...
			if (structKeyExists(astr, n)){
				// ... and is not an array...
				if (not isArray(astr[n])){
					// ... get this item into temp variable, ...
					tmpContainer = astr[n];
					// ... setup array for this item beacuse we have multiple items with same name, ...
					astr[n] = arrayNew(1);
					// ... and reassing temp item as a first element of new array:
					astr[n][1] = tmpContainer;
				}
				else{
					// Item is already an array:
					
				}
				if (arrayLen(axml.XmlChildren[i].XmlChildren) gt 0){
					// recurse call: get complex item:
					astr[n][arrayLen(astr[n])+1] = ConvertXmlToStruct(axml.XmlChildren[i], structNew());
				}
				else{
					// else: assign node value as last element of array:
					astr[n][arrayLen(astr[n])+1] = axml.XmlChildren[i].XmlText;
				}
			}
			else{
				// This is not a struct. This may be first tag with some name.
				// This may also be one and only tag with this name.
				//If context child node has child nodes (which means it will be complex type):
				if (arrayLen(axml.XmlChildren[i].XmlChildren) gt 0){
					// recurse call: get complex item:
					astr[n] = ConvertXmlToStruct(axml.XmlChildren[i], structNew());
				}
				else{
					if (IsStruct(aXml.XmlAttributes) AND StructCount(aXml.XmlAttributes)){
						at_list = StructKeyList(aXml.XmlAttribute);
						for (atr=1; atr<=listlen(at_list); atr++){
							if (ListgetAt(at_list,atr) CONTAINS "xmlns:"){
								// remove any namespace attribute
								Structdelete(axml.XmlAttributes, listgetAt(at_list,atr));
							}
						}
						// if there are any atributes left, append them to the respons
						if (StructCount(axml.XmlAttributes) GT 0){
							astr['_attributes'] = axml.XmlAttributes;
						}
					}
					// else: assign node value as last element of array:
					// if there are any attributes on this elemen
					if (IsStruct(aXml.XmlChildren[i].XmlAttributes) AND StructCount(aXml.XmlChildren[i].XmlAttributes) GT 0){
						// assign the text
						astr[n] = axml.XmlChildren[i].XmlText;
						// check if there are no attributes with xmlns: , we dont want namespaces to be in the respons
						attrib_list = StructKeylist(axml.XmlChildren[i].XmlAttributes);
						for (attrib=1; attrib<=listLen(attrib_list); attrib++){
							if (ListgetAt(attrib_list,attrib) CONTAINS "xmlns:"){
								// remove any namespace attribute
								Structdelete(axml.XmlChildren[i].XmlAttributes, listgetAt(attrib_list,attrib));
							}
						}
						// if there are any atributes left, append them to the respons
						if (StructCount(axml.XmlChildren[i].XmlAttributes) GT 0){
							astr[n&'_attributes'] = axml.XmlChildren[i].XmlAttributes;
						}
					}
					else{
						 astr[n] = axml.XmlChildren[i].XmlText;
					}
				}
			}
		}

		// return struct:
		return astr;
	}

}