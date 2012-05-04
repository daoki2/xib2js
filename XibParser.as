/**
 * XIB parser for Titanium Mobile
 * @author Copyright (c) 2010-2012 daoki2
 * @version 2.0.0
 * 
 * Copyright (c) 2010-2012 daoki2
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

package {
    import flash.display.*;
    import flash.errors.IllegalOperationError;
    import flash.filesystem.*;
    import flash.utils.*;
    import mx.controls.*;
    import mx.utils.*;

    /**
     * This is a utility class to parse the .xib file for Titanium Mobile
     */
    public class XibParser {

	private static const _TYPE:Array = [
					    "com.apple.InterfaceBuilder3.CocoaTouch.XIB",
					    "com.apple.InterfaceBuilder3.CocoaTouch.XIB",
					    "com.apple.InterfaceBuilder3.CocoaTouch.iPad.XIB",
					    "com.apple.InterfaceBuilder3.CocoaTouch.iPad.XIB"
					    ];
	private static const _VERSION:Array = [
					       "7.10",
					       "8.00",
					       "7.10",
					       "8.00"
					       ];
	private static var _xib:XML;
	private static var _rootObjects:Array = [];
	private static var _objRecords:Array = [];

	/**
	 * XibParser class can not create instance
	 */
	public function XibParser() {
	    throw new IllegalOperationError("XibParser class can not create instance");
	}

	/**
	 * parse the .xib file
	 */
	public static function exec(_file:File, _checkVersion:Boolean = true):void {
	    // read .xib file
	    var _fs:FileStream = new FileStream();
	    _fs.open(_file, FileMode.READ);
	    _xib = new XML(_fs.readUTFBytes(_fs.bytesAvailable));
	    _fs.close();

	    if (_checkVersion) {
		if (!checkVersion()) {
		    Alert.show("This version of .xib file is not supported: " + _xib.@version.toString(), "ERROR");
		    trace("Version error");
		    return;
		}
	    }

	    // parse the IBObjectContainer first because it is easy to get the name of the object
	    var children:XMLList;
	    var child:XML;
	    children = _xib.children();
	    for each (child in children) {
		switch (child.name().toString()) {
		case "data":
		    parseIBObjectContainerData(child);
		    break;
		default:
		    trace("Unknown XML list:", child.name());
		    break;
		}
	    }

	    children = _xib.children();
	    for each (child in children) {
		switch (child.name().toString()) {
		case "data":
		    parseRootObjectsData(child);
		    break;
		default:
		    trace("Unknown XML list:", child.name());
		    break;
		}
	    }
	}

	/**
	 * cleanup the parser
	 */
	public static function cleanup():void {
	    _rootObjects = new Array();
	    _objRecords = new Array();
	    _xib = null;
	}

	/**
	 * Return the parsed data
	 */
	public static function getParsedData():Array {
	    return _rootObjects;
	}

	/**
	 * parse IBObjectContainer of <data>
	 */
	private static function parseIBObjectContainerData(xml:XML):void {
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		switch (child.name().toString()) {
		case "object":
		    if (child.attribute("class").toString() == "IBObjectContainer" && child.@key.toString() == "IBDocument.Objects") {
			parseObjectContainer(child);
			break;
		    }
		    break;
		default:
		    // Do nothing
		    break;
		}
	    }
	}

	/**
	 * parse RootObjects of <data>
	 */
	private static function parseRootObjectsData(xml:XML):void {
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		switch (child.name().toString()) {
		case "array":
		case "object":
		    if (child.attribute("class").toString() == "NSMutableArray" && child.@key.toString() == "IBDocument.RootObjects") {
			parseRootObject(child);
			break;
		    }
		    break;
		default:
		    // Do nothing
		    break;
		}
	    }
	}

	/**
	 * parse RootObjects
	 */
	private static function parseRootObject(xml:XML):void {
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		switch (child.name().toString()) {
		case "object":
		    var _result:Object = null;
		    switch (child.attribute("class").toString()) {
		    case "IBUIWindow":
			_result = parseUIWindow(child);
			break;
		    case "IBUITabBarController":
			_result = parseUITabBarController(child);
			break;
		    case "IBUINavigationController":
			_result = parseUINavigationController(child);
			break;
		    case "IBUIViewController":
			_result = parseUIViewController(child);
			break;
		    case "IBUITableViewController":
			_result = parseUITableViewController(child);
			break;
		    case "IBUISplitViewController":
			_result = parseUISplitViewController(child);
			break;
		    case "IBUIImagePickerController":
			_result = parseUIImagePickerController(child);
			break;
		    case "IBUITableViewCell":
			_result = parseUITableViewCell(child);
			break;
		    case "IBUIView":
			_result = parseUIView(child);
			break;
		    default:
			// Do nothing
			trace("# skipped:1", child.attribute("class").toString());
			break;
		    }
		    if (_result != null) {
			_rootObjects.push(_result);
		    }
		    break;
		default:
		    // Do nothing
		    trace("# skipped:2", child.name().toString());
		    break;
		}
	    }
	}

	/**
	 * parse UIWindow
	 */
	private static function parseUIWindow(xml:XML):Object {
	    trace("parse UIWindow", getObjectName(xml.@id.toString()), xml.@id);
	    return {obj:"IBUIWindow", name:getObjectName(xml.@id.toString()), id:xml.@id.toString(), subviews:getSubviews(xml), propertires:getProperties(xml)};
	}
	
	/**
	 * parse UITabBarController
	 */
	private static function parseUITabBarController(xml:XML):Object {
	    trace("parse IBUITabBarController", getObjectName(xml.@id.toString()), xml.@id);
	    var _viewControllers:Array = [];
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		switch (child.name().toString()) {
		case "object":
		    if (child.@key.toString() == "IBUISelectedViewController") {
			_viewControllers.push(parseViewController(child));
		    }
		    if (child.@key.toString() == "IBUIViewControllers") {
			var _result:Array = parseViewControllers(child);
			if (_result.length > 0)
			    _viewControllers = _viewControllers.concat(_result);
		    }
		    break;
		default:
		    // Do nothing
		    trace("# skipped:3", child.name().toString());
		    break;
		}
	    }
	    return {obj:"IBUITabBarController", name:getObjectName(xml.@id.toString()), id:xml.@id.toString(), views:_viewControllers};
	}

	/**
	 * parse ViewControllers
	 */
	private static function parseViewControllers(xml:XML):Array {
	    trace("parseViewControllers");
	    var _views:Array = [];
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		var _result:Object = parseViewController(child);
		if (_result != null)
		    _views.push(_result);
	    }
	    return (_views.length > 0 ? _views : null);
	}

	/**
	 * parse ViewController
	 */
	private static function parseViewController(xml:XML):Object {
	    switch (xml.name().toString()) {
	    case "object":
		if (xml.attribute("class").toString() == "IBUIViewController") {
		    return parseUIViewController(xml);
		}
		if (xml.attribute("class").toString() == "IBUINavigationController") {
		    return parseUINavigationController(xml);
		}
		if (xml.attribute("class").toString() == "IBUITableViewController") {
		    return parseUITableViewController(xml);
		}
		if (xml.attribute("class").toString() == "IBUIImagePickerController") {
		    return parseUIImagePickerController(xml);
		}
		break;
	    default:
		// do nothing
		trace("# skipped:4", xml.name().toString());
		break;
	    }
	    return null;
	}

	/**
	 * parse UIViewController
	 */
	private static function parseUIViewController(xml:XML):Object {
	    trace("parse UIViewController", getObjectName(xml.@id.toString()), xml.@id);
	    var _tabItem:Object = null;
	    var _navItem:Object = null;
	    var _view:Object = null;
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		switch(child.name().toString()) {
		case "object":
		    switch(child.attribute("class").toString()) {
		    case "IBUINavigationItem":
			trace("UINavigationItem");
			_navItem = {title:getUITitle(child)};
			break;
		    case "IBUITabBarItem":
			trace("UITabBarItem");
			_tabItem = {title:getUITitle(child)};
			break;
		    case "IBUIView":
			_view = parseUIView(child);
			break;
		    case "IBUIScrollView":
			_view = parseUIScrollView(child);
			break;
		    case "IBUITextView":
			_view = parseUITextView(child);
			break;
		    case "IBUIImageView":
			_view = parseUIImageView(child);
			break;
		    case "IBUITableView":
			_view = parseUITableView(child);
			break;
		    case "IBUIWebView":
			_view = parseUIWebView(child);
			break;
		    case "IBMKMapView":
			_view = parseMKMapView(child);
			break;
		    default:
			//_view = parseControlls(child);
			break;
		    }
		    break;
		default:
		    // do nothing
		    trace("# skipped:5", child.name().toString());
		    break;
		}
	    }
	    return {obj:"IBUIViewController", name:getObjectName(xml.@id.toString()), id:xml.@id.toString(), view:_view, navItem:_navItem, tabItem:_tabItem};
	}

	/**
	 * parse UINavigationController
	 */
	private static function parseUINavigationController(xml:XML):Object {
	    trace("parse UINavigationController", getObjectName(xml.@id.toString()), xml.@id);
	    var _views:Array = [];
	    var children:XMLList = xml.children();
	    var _tabItem:Object = null;
	    for each (var child:XML in children) {
		switch(child.name().toString()) {
		case "array":
		case "object":
		    //if (child.attribute("class").toString() == "NSMutableArray" && child.@key.toString() == "IBUIViewControllers") {
		    if (child.@key.toString() == "IBUIViewControllers") {
			_views = parseViewControllers(child);
		    }
		    if (child.attribute("class").toString() == "IBUITabBarItem") {
			trace("UITabBarItem");
			_tabItem = {title:getUITitle(child)};
		    }
		    break;
		default:
		    // do nothing
		    trace("# skipped:6", child.name().toString());
		    break;
		}
	    }
	    return {obj:"IBUINavigationController", name:getObjectName(xml.@id.toString()), id:xml.@id.toString(), views:_views, tabItem:_tabItem};
	}

	/**
	 * parse UITableViewController
	 */
	private static function parseUITableViewController(xml:XML):Object {
	    trace("parse UITableViewController", getObjectName(xml.@id.toString()), xml.@id);
	    var _tabItem:Object = null;
	    var _navItem:Object = null;
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		switch(child.name().toString()) {
		case "object":
		    switch(child.attribute("class").toString()) {
		    case "IBUINavigationItem":
			trace("UINavigationItem");
			_navItem = {title:getUITitle(child)};
			break;
		    case "IBUITabBarItem":
			trace("UITabBarItem");
			_tabItem = {title:getUITitle(child)};
			break;
		    case "IBUITableView":
			trace("UITableView");
			break;
		    default:
			// do nothing
			break;
		    }
		default:
		    // do nothing
		    break;
		}
	    }
	    return {obj:"IBUITableViewController", name:getObjectName(xml.@id.toString()), id:xml.@id.toString(), navItem:_navItem, tabItem:_tabItem}
	}

	/**
	 * parse UIImagePickerController
	 */
	private static function parseUIImagePickerController(xml:XML):Object {
	    trace("parse UIImagePickerController", getObjectName(xml.@id.toString()), xml.@id);
	    var _navBar:Object = null;
	    var _views:Array;
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		switch(child.name().toString()) {
		case "array":
		case "object":
		    if (child.attribute("class").toString() == "IBUINavigationBar") {
			// do nothing
		    }
		    if (child.attribute("class").toString() == "NSMutableArray" && child.@key.toString() == "IBUIViewControllers") {
			_views = parseViewControllers(child);
		    }
		    break;
		default:
		    // do nothing
		    trace("# skipped:7", child.name().toString());
		    break;
		}
	    }
	    return {obj:"IBUIImagePickerController", name:getObjectName(xml.@id.toString()), id:xml.@id.toString(), views:_views, navBar:_navBar};
	}
	/**
	 * parse UISplitViewController
	 */
	private static function parseUISplitViewController(xml:XML):Object {
	    trace("parse IBUISplitViewController", getObjectName(xml.@id.toString()), xml.@id);
	    var _viewControllers:Array = [];
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		switch (child.name().toString()) {
		case "object":
		    if (child.@key.toString() == "IBUIMasterViewController") {
			_viewControllers.push(parseUINavigationController(child));
		    }
		    if (child.@key.toString() == "IBUIDetailViewController") {
			if (child.attribute("class").toString() == "IBUIViewController")
			    _viewControllers.push(parseUIViewController(child));
			if (child.attribute("class").toString() == "IBUINavigationController")
			    _viewControllers.push(parseUINavigationController(child));			    
		    }
		    break;
		default:
		    // Do nothing
		    trace("# skipped:8", child.name().toString());
		    break;
		}
	    }
	    return {obj:"IBUISplitViewController", name:getObjectName(xml.@id.toString()), id:xml.@id.toString(), views:_viewControllers};
	}

	/**
	 * parse UITableViewCell
	 */
	private static function parseUITableViewCell(xml:XML):Object {
	    trace("parse UITableViewCell", getObjectName(xml.@id.toString()), xml.@id);
	    var _subviews:Array = [];
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		switch(child.name().toString()) {
		case "array":
		case "object":
		    if (child.attribute("class").toString() == "NSMutableArray" && child.@key.toString() == "NSSubviews") {
			trace("NSSubviews");
			_subviews = getSubviews(child);
		    }
		    break;
		default:
		    // do nothing
		    trace("# skipped:9", child.name().toString());
		    break;
		}
	    }
	    return {obj:"IBUITableViewCell", name:getObjectName(xml.@id.toString()), id:xml.@id.toString, subviews:_subviews, properties:getProperties(xml)};
	}

	/**
	 * parse UIView
	 */
	private static function parseUIView(xml:XML, scrollable:Boolean = false):Object {
	    trace("parse", (scrollable ? "IBUIScrollView" : "IBUIView"), xml.@id);
	    var _subviews:Array = [];
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		switch(child.name().toString()) {
		case "array":
		case "object":
		    if (child.attribute("class").toString() == "NSMutableArray" && child.@key.toString() == "NSSubviews") {
			trace("NSSubviews");
			_subviews = getSubviews(child);
		    }
		    break;
		default:
		    // do nothing
		    trace("# skipped:10", child.name().toString());
		    break;
		}
	    }
	    return {obj:(scrollable ? "IBUIScrollView" : "IBUIView"), name:getObjectName(xml.@id.toString()), id:xml.@id.toString, subviews:_subviews, properties:getProperties(xml)};
	}

	/**
	 * parse UIScrollView
	 */
	private static function parseUIScrollView(xml:XML):Object {
	    return parseUIView(xml, true);
	}

	/**
	 * parse UITextView
	 */
	private static function parseUITextView(xml:XML):Object {
	    trace("parse IBUITextView", getObjectName(xml.@id.toString()), xml.@id.toString());
	    return {obj:"IBUITextView", name:getObjectName(xml.@id.toString()), id:xml.@id.toString(), properties:getProperties(xml)};
	}

	/**
	 * parse UIImageView
	 */
	private static function parseUIImageView(xml:XML):Object {
	    trace("parse IBUIImageView", getObjectName(xml.@id.toString()), xml.@id.toString());
	    return {obj:"IBUIImageView", name:getObjectName(xml.@id.toString()), id:xml.@id.toString(), properties:getProperties(xml)};
	}

	/**
	 * parse UITableView
	 */
	private static function parseUITableView(xml:XML):Object {
	    trace("parse IBUITableView", getObjectName(xml.@id.toString()), xml.@id.toString());
	    return {obj:"IBUITableView", name:getObjectName(xml.@id.toString()), id:xml.@id.toString(), properties:getProperties(xml)};
	}
	
	/**
	 * parse UIWebView
	 */
	private static function parseUIWebView(xml:XML):Object {
	    trace("parse IBUIWebView", getObjectName(xml.@id.toString()), xml.@id.toString());
	    return {obj:"IBUIWebView", name:getObjectName(xml.@id.toString()), id:xml.@id.toString(), properties:getProperties(xml)};
	}

	/**
	 * parse UIMKMapView
	 */
	private static function parseMKMapView(xml:XML):Object {
	    trace("parse IBMKMapView", getObjectName(xml.@id.toString()), xml.@id.toString());
	    return {obj:"IBMKMapView", name:getObjectName(xml.@id.toString()), id:xml.@id.toString(), properties:getProperties(xml)};
	}

	/**
	 * parse Subviews
	 */
	private static function getSubviews(xml:XML):Array {
	    var result:Array = [];
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		switch (child.name().toString()) {
		case "array":
		case "object":
		    switch(child.attribute("class").toString()) {
		    case "NSMutableArray":
			if (child.@key.toString() == "NSSubviews") {
			    result.push({obj:"NSSubviews", subviews:getSubviews(child)});
			}
			break;
		    case "IBUIActivityIndicatorView":
		    case "IBUIButton":
		    case "IBUIDatePicker":
		    case "IBUIImageView":
		    case "IBUILabel":
		    case "IBUIPickerView":
		    case "IBUIProgressView":
		    case "IBUISearchBar":
		    case "IBUISegmentedControl":
		    case "IBUISlider":
		    case "IBUISwitch":
		    case "IBUITextField":
		    case "IBUITextView":
		    case "IBUIToolbar":
			trace("parse", child.attribute("class"), child.@id);
			result.push({obj:child.attribute("class").toString(), name:getObjectName(child.@id.toString()), id:child.@id.toString(), properties:getProperties(child)});
			break;
		    case "IBUIView":
			result.push(parseUIView(child));
			break;
		    case "IBUIScrollView":
			result.push(parseUIScrollView(child));
			break;
		    case "IBUITextView":
			result.push(parseUITextView(child));
			break;
		    case "IBUIImageView":
			result.push(parseUIImageView(child));
			break;
		    case "IBUITableView":
			result.push(parseUITableView(child));
			break;
		    case "IBUIWebView":
			result.push(parseUIWebView(child));
			break;
		    case "IBMKMapView":
			result.push(parseMKMapView(child));
			break;
		    default:
			// Do nothing;
			trace("# skipped:11", child.attribute("class").toString());
			break;
		    }
		    break;
		default:
		    // Do nothing
		    trace("# skipped:12", child.name().toString());
		    break;
		}
	    }
	    return result;
	}

	/**
	 * parse property
	 */
	private static function getProperties(xml:XML):Array {
	    var result:Array = [];
	    var children:XMLList = xml.children();
	    var _children:XMLList;
	    var _child:XML;
	    for each (var child:XML in children) {
		switch (child.name().toString()) {
		case "string":
		    if (child.@key.toString() == "NSFrame") {
			trace("parse NSFrame", child.toString());
			result.push({type:"frame", value:child.toString()});
			break;
		    }
		    if (child.@key.toString() == "NSFrameSize") {
			trace("parse NSFrameSize", child.toString());
			result.push({type:"framesize", value:child.toString()});
			break;
		    }
		    if (child.@key.toString() == "IBUIText") {
			trace("parse IBUIText", child.toString());
			if (xml.attribute("class").toString() == "IBUITextField" || xml.attribute("class").toString() == "IBUITextView") {
			    result.push({type:"value", value:"'" + child.toString() + "'"});
			} else {
			    result.push({type:"text", value:child.toString()});
			}
			break;
		    }
		    if (child.@key.toString() == "IBUINormalTitle") {
			trace("parse IBUINormalTitle", child.toString());
			result.push({type:"title", value:child.toString()});
			break;
		    }
		    break;
		case "bool":
		    if (child.@key.toString() == "IBUIOn") {
			trace("parse IBUIOn", child.toString());
			result.push({type:"value", value:(child.toString() == "YES" ? "true" : "false")});			
		    }
		    break;
		case "float":
		    if (child.@key.toString() == "IBUIValue" || child.@key.toString() == "IBUIProgress") {
			trace("parse IBUIValue", child.toString());
			result.push({type:"value", value:child.toString()});
			break;
		    }
		    if (child.@key.toString() == "IBUIMinValue") {
			trace("parse IBUIMinValue", child.toString());
			result.push({type:"min", value:child.toString()});
			break;
		    }
		    if (child.@key.toString() == "IBUIMaxValue") {
			trace("parse IBUIMaxValue", child.toString());
			result.push({type:"max", value:child.toString()});
			break;
		    }
		    break;
		case "object":
		    // parse Font
		    if (child.@key.toString() == "IBUIFont") {
			trace("parse IBUIFont", child.toString());
			_children = child.children();
			var _fontName:String = "";
			var _fontSize:String = "";
			for each (_child in _children) {
			    switch(_child.name().toString()) {
			    case "string":
				if (_child.@key.toString() == "NSName") {
				    _fontName = _child.toString();
				}
				break;
			    case "double":
				if (_child.@key.toString() == "NSSize") {
				    _fontSize = _child.toString();
				}
				break;
			    default:
				trace("# skipped:13", _child.name().toString());
				break;
			    }
			}
			result.push({type:"font", value:_fontName + "," + _fontSize});			
			break;
		    }
		    // parse Segement
		    if (child.@key.toString() == "IBSegmentTitles") {
			trace("parse IBSegmentTitles", child.toString());
			_children = child.children();
			var _labels:String = "";
			for each (_child in _children) {
			    if (_child.name().toString() == "string") {
				_labels += "'" + _child.toString() + "', ";
			    }
			}
			result.push({type:"labels", value:"[" + _labels.substring(0, _labels.length - 2) + "]"});
			break;
		    }
		    // parse Toolbar
		    if (child.@key.toString() == "IBUIItems") {
			_children = child.children();
			var _toolbar:String = "";
			for each (_child in _children) {			   
			    if (_child.attribute("class").toString() == "IBUIBarButtonItem") {
				trace("parse IBUIBarButtonItem", _child.toString());
				var __children:XMLList = _child.children();
				var _title:String = "";
				var _id:String = "";
				var _width:String = "";
				for each(var __child:XML in __children) {
				    switch (__child.name().toString()) {
				    case "string":
					if (__child.@key.toString() == "IBUITitle") {
					    _title = __child.toString();
					}
					break;
				    case "int":
					if (__child.@key.toString() == "IBUISystemItemIdentifier") {
					    _id = __child.toString();
					}
					break;
				    case "float":
					if (__child.@key.toString() == "IBUIWidth") {
					    _width = __child.toString();
					}
					break;
				    default:
					trace("# skipped:14", __child.name().toString());
					break;
				    }						
				}
				_toolbar += "{title: " + _title + ", id: " + _id + ", width: " + _width + "}, ";
			    }
			}
			result.push({type:"toolbar", value:"[" + _toolbar.substring(0, _toolbar.length - 2) + "]"});
			break;
		    }
		    // parse NSColor
		    if (child.attribute("class").toString() == "NSColor") {
			_children = child.children();
			var _colorSpace:int = -1;
			var _bytes:Array = [];
			var _color:String = "";
			for each (_child in _children) {
			    switch (_child.name().toString()) {
			    case "int":
				if (_child.@key.toString() == "NSColorSpace") {
				    _colorSpace = _child.toString();
				}
				break;
			    case "bytes":
				_color = convertToColor(_child.toString(), _colorSpace, _child.@key.toString());
				break;
			    default:
				// do nothing
				break;
			    }
			}
			if (_color != "") {
			    var _colorType:String = "color";
			    switch(child.@key.toString()) {
			    case "IBUIBackgroundColor":
				result.push({type:"backgroundColor", value:_color});
				break;
			    case "IBUINormalTitleColor":
			    case "IBUITextColor":
				result.push({type:"color", value:_color});
				break;
			    default:
				trace("# skipped:15", child.@key.toString());
				break;
			    }
			}
			break;
		    }
		    break;
		default:
		    // Do nothing
		    trace("# skipped:16", child.name().toString());
		    break;
		}
	    }
	    return result;
	}
	
	/**
	 * parse ObjectContainer
	 */
	private static function parseObjectContainer(xml:XML):void {
	    trace("parse ObjectContainer");
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		switch (child.name().toString()) {
		case "object":
		    if (child.attribute("class").toString() == "IBMutableOrderedSet" && child.@key.toString() == "objectRecords") {
			parseObjectRecords(child);
			break;
		    }
		    break;
		default:
		    // Do nothing
		    trace("# skipped:17", child.name().toString());
		    break;
		}
	    }
	}

	/**
	 * parse ObjectRecords
	 */
	private static function parseObjectRecords(xml:XML):void {
	    trace("parse ObjectRecords");
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		switch (child.name().toString()) {
		case "array":
		case "object":
		    //if (child.attribute("class").toString() == "NSArray" && child.@key.toString() == "orderedObjects") {
		    if (child.@key.toString() == "orderedObjects") {
			parseOrderedObject(child);
			break;
		    }
		    break;
		default:
		    // do nothing
		    break;
		}
	    }
	}

	/**
	 * parse OrderedObjects
	 */
	private static function parseOrderedObject(xml:XML):void {
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		switch (child.name().toString()) {
		case "object":
		    if (child.attribute("class").toString() == "IBObjectRecord") {
			if (child.string.toString() != "") {
			    for (var i:uint = 0; i < child.reference.length(); i++) {
				if (child.reference[i].@key.toString() == "object") {
				    trace("add id:", child.reference[i].@ref.toString(), "name:", child.string.toString());			    
				    _objRecords.push({id:child.reference[i].@ref.toString(), name:child.string.toString()});
				}
			    }
			    break;
			}
		    }
		    break;
		default:
		    // do nothing
		    trace("# skipped:18", child.name().toString());
		    break;
		}
	    }
	}

	/**
	 * convert base64 encoded value to color value
	 */
	private static function convertToColor(_code:String, type:int, key:String):String {
	    //trace("convertToColor", _code, type, key);
	    var result:String = "";

	    // The _code is not just Base64 encoded data
	    // It seems the padding character is "AA" not "=". Why?
	    if (_code.length <=3) {
		if (_code == "MAA") {
		    return "#000000";
		} else {
		    _code = _code.substring(0, _code.length -1) + "==";
		}
	    } else {
		var _padding:String = _code.substring(_code.length - 2, _code.length);
		if (_padding == "AA") {
		    _code = _code.substring(0, _code.length - 2);
		}
	    }
	    var _padNum:int = _code.length % 4;
	    if (_padNum != 0) {
		while(_padNum != 4) {
		    _code += "=";
		    _padNum++;
		}
	    }
	    var decoder:Base64Decoder = new Base64Decoder();
	    decoder.decode(_code);
	    var _bytes:ByteArray = decoder.toByteArray();
	    var i:int;
	    var _r:String;
	    var _g:String;
	    var _b:String;
	    var _color:Array;
	    switch(key) {
	    case "NSRGB":
		_color = _bytes.readUTFBytes(_bytes.length).split(" ");
		_r = uint(parseFloat(_color[0])*255).toString(16);
		_g = uint(parseFloat(_color[1])*255).toString(16);
		_b = uint(parseFloat(_color[2])*255).toString(16);
		result = "#" + (_r.length < 2 ? "0" + _r : _r) + (_g.length < 2 ? "0" + _g : _g) + (_b.length < 2 ? "0" + _b : _b);
		if (_color.length == 4)
		    result += ":" + parseFloat(_color[3]);
		break;
	    case "NSCMYK": 
		_color = _bytes.readUTFBytes(_bytes.length).split(" ");
		var _c:float = parseFloat(_color[0]);
		var _m:float = parseFloat(_color[1]);
		var _y:float = parseFloat(_color[2]);
		var _k:float = parseFloat(_color[3]);
		_r = uint((1 - Math.min(1, _c * (1 - _k) + _k)) * 255).toString(16);
		_g = uint((1 - Math.min(1, _m * (1 - _k) + _k)) * 255).toString(16);
		_b = uint((1 - Math.min(1, _y * (1 - _k) + _k)) * 255).toString(16);
		result = "#" + (_r.length < 2 ? "0" + _r : _r) + (_g.length < 2 ? "0" + _g : _g) + (_b.length < 2 ? "0" + _b : _b);
		if (_color.length == 5)
		    result += ":" + parseFloat(_color[4]);
		break;
	    case "NSWhite": // Grayscale
		_color = _bytes.readUTFBytes(_bytes.length).split(" ");
		_r = uint(parseFloat(_color[0])*255).toString(16);
		result = "#" + (_r.length < 2 ? "0" + _r : _r) + (_r.length < 2 ? "0" + _r : _r) + (_r.length < 2 ? "0" + _r : _r);
		if (_color.length == 2)
		    result += ":" + parseFloat(_color[1]);
		break;
	    default:
		trace("# skipped:19", key, type);
		break;
	    }
	    return result;
	}

	/**
	 * get IBUITitle
	 */
	private static function getUITitle(xml:XML):String {
	    var children:XMLList = xml.children();
	    for each (var child:XML in children) {
		if (child.@key.toString() == "IBUITitle")
		    return child.toString();
	    }
	    return "";
	}

	/**
	 * get the name of the object
	 */
	private static function getObjectName(id:String):String {
	    for each (var val:* in _objRecords) {
		if (val.id == id) {
		    return val.name;
		}
	    }
	    return "";
	}

	/**
	 * Check version
	 */
	private static function checkVersion():Boolean {
	    if (_xib.name().toString() == "archive") {
		trace(_xib.@type, _xib.@version);
		for (var i:uint = 0; i < _TYPE.length; i++) {
		    if (_xib.@type.toString() == _TYPE[i] && _xib.@version.toString() == _VERSION[i])
			return true;
		}
	    }
	    return false;
	}
    }
}
