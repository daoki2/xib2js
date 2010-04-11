/**
 * The Preference Utility Class for AIR Application
 *
 * @author      Copyright (c) 2008 daoki2
 * @version     1.0.0
 * @link        http://snippets.libspark.org/
 * @link        http://homepage.mac.com/daoki2/
 *
 * Copyright (c) 2008 daoki2
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package org.libspark.utils {
    import flash.errors.IllegalOperationError;
    import flash.filesystem.*;
    import mx.collections.ArrayCollection;
    import mx.utils.Base64Encoder;
    import mx.utils.Base64Decoder;

    public class PreferenceUtil {

	/**
	 * Constructor
	 */
        public function PreferenceUtil() {
            throw new IllegalOperationError("PreferenceUtil class can not create instance");
        }

	/**
	 * Load the preference data and setup to the property
	 * @param	obj		Object to store the preference data
	 * @param	filename	The filename of the preference file
	 * @return	Object		Return the status of this operation
	 *                                - status : If the operation succeed or not
	 *                                - message: The message
	 */
        public static function load(obj:Object, filename:String):Object {
            try {
                var file:File = File.applicationStorageDirectory.resolvePath(filename);
                var fs:FileStream = new FileStream();
                fs.open(file, FileMode.READ);
                var xml:XML = new XML(fs.readUTFBytes(file.size));
                setupProperties(obj, xml.children());
                fs.close();
            } catch (err:Error) {
                return {status: false, message: err.message};
            }
            return {status: true, message: ""};
        }

        private static function setupProperties(obj:Object, xml:XMLList, txt:String = null):void {
            for each(var val:* in xml) {
                if (val.children().length() > 1) {
                    setupProperties(obj[val.name()], val.children(), txt == null ? null : txt + "." + val.name());
                } else {
                    if (val.children().name() != null) {
                        setupProperties(obj[val.name()], val.children(), txt == null ? null : txt + "." + val.name());
                    } else {
			//trace(val.name());
			if (obj[val.name()] is Boolean) {
			    //trace("Boolean");
			    obj[val.name()] = val == "true" ? true : false;
			} else if (obj[val.name()] is Number) {
			    //trace("Number");
			    obj[val.name()] = Number(val);
			} else if (obj[val.name()] is ArrayCollection) {
			    //trace("ArrayCollection");
			    obj[val.name()] = Base64ToArrayCollection(val);
			} else if (obj[val.name()] is Array) {
			    //trace("Array");
			    obj[val.name()] = Base64ToArray(val);
			} else if (obj[val.name()] is XML) {
			    //trace("XML");
			    obj[val.name()] = Base64toXML(val);
			} else if (obj[val.name()] is String) {
			    //trace("String");
			    obj[val.name()] = String(val);
			} else {
			    //trace("Unknown");
			    obj[val.name()] = val;
			}
                    }
                }
            }
        }

	/**
	 * Save preference data to XML file
	 * @param	obj		Object that stores the preference data
	 * @param	prefList	ArrayCollection of the properties that stores the data
	 * @param	filename	The filename of the preference file
	 */
        public static function save(obj:Object, prefList:ArrayCollection, filename:String):void {
            var xmlString:String = "<properties>\n";
            for each (var val:* in prefList)
			 xmlString += buildXML(obj, val, "  ");
            xmlString += "</properties>";
            try {
                var file:File = File.applicationStorageDirectory.resolvePath(filename);
                var fs:FileStream = new FileStream();
                fs.open(file, FileMode.WRITE);
                fs.writeUTFBytes(xmlString);
                fs.close();
            } catch (err:Error) {
                //trace(err.message);
                return;
            }
        }

        private static function buildXML(obj:Object, property:String, indent:String):String {
            var result:String = "";
            var elements:ArrayCollection = new ArrayCollection(property.split("."));
            for each(var val:* in elements) {
                result += indent + "<" + val + ">\n";
                if (elements.length > 1) {
                    obj = obj[elements[0]];
                    elements.removeItemAt(0);
                    result += buildXML(obj, elements.toArray().join("."), indent + "  ");
                } else {
		    var value:String;
		    if(obj[val] is XML)
			value = XMLtoBase64(obj[val]);
		    else if (obj[val] is ArrayCollection)
			value = ArrayCollectionToBase64(obj[val]);
		    else if (obj[val] is Array)
			value = ArrayToBase64(obj[val]);
		    else
			value = obj[val];
                    result += indent + "  " + value + "\n";
		}
                result += indent + "</" + val + ">\n";
            }
            return result;
        }
	
	private static function XMLtoBase64(_xml:XML):String {
	    var encoder:Base64Encoder = new Base64Encoder();
	    encoder.encode(_xml.toXMLString());
	    return encoder.toString();
	}

	private static function Base64toXML(txt:String):XML {
	    var decoder:Base64Decoder = new Base64Decoder();
	    decoder.decode(txt);
	    return XML(decoder.toByteArray().toString());
	}
	private static function ArrayCollectionToBase64(_obj:ArrayCollection):String {
	    var txt:String = "";
	    var result:String = "";
	    for each(var val:* in _obj) {
		txt = "";
		for (var prop:* in val) {
		    if (prop != "mx_internal_uid")
			txt += prop + ":" + val[prop] + "\t";
		}
		result += txt.substring(0, txt.length - 1) + "\n";
	    }
	    result = result.substring(0, result.length - 1);
	    var encoder:Base64Encoder = new Base64Encoder();
	    encoder.encode(result);
	    return encoder.toString();
	}

	private static function Base64ToArrayCollection(txt:String):ArrayCollection {
	    var result:ArrayCollection = new ArrayCollection();
	    var decoder:Base64Decoder = new Base64Decoder();
	    decoder.decode(txt);
	    var line:Array = decoder.toByteArray().toString().split("\n");
	    for each (var val:* in line) {
		var prop:Array = val.split("\t");
		var obj:Object = new Object();
		for each(var items:* in prop) {
		    var item:Array = items.split(":");
		    obj[item[0]] = item[1];
		}
		result.addItem(obj);
	    }
	    return result;
	}

	private static function ArrayToBase64(_obj:Array):String {
	    var txt:String = _obj.join("\t");
	    var encoder:Base64Encoder = new Base64Encoder();
	    encoder.encode(txt);
	    return encoder.toString();
	}

	private static function Base64ToArray(txt:String):Array {
	    var decoder:Base64Decoder = new Base64Decoder();
	    decoder.decode(txt);
	    var result:String = decoder.toByteArray().toString();
	    return result.split("\t");
	}
    }
}
