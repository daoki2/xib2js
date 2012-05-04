/**
 * JavaScript Code Generator for Titanium Mobile
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
    import flash.errors.IllegalOperationError;
    import flash.filesystem.*;

    /**
     * This is a utility class to generate the JavaScript code for Titanium Mobile
     */
    public class JsCodegen {

	private static var _genCode:Array = [];
	private static var _appJs:Object;
	private static var _id:Number = 0;

	/**
	 * JsCodegen class can not create instance
	 */
	public function JsCodegen() {
	    throw new IllegalOperationError("JsCodegen class can not create instance");
	}

	/**
	 * generate the JavaScript code
	 */
	public static function exec(parsedData:Array):void {
	    _appJs = createFile("app.js");
	    for each (var val:* in parsedData) {
		if (val.hasOwnProperty("obj")) {
		    switch(val.obj) {
		    case "IBUIWindow":
			generateUIWindow(val);
			break;
		    case "IBUITabBarController":
			generateUITabBarController(val);
			break;
		    case "IBUIViewController":
			generateUIViewController(val);
			break;
		    case "IBUINavigationController":
			generateUINavigationController(val);
			break;
		    case "IBUITableViewController":
			generateUITableViewController(val);
			break;
		    case "IBUISplitViewController":
			generateUISplitViewController(val);
			break;
		    case "IBUITableViewCell":
			generateUITableViewCell(val);
			break;
		    case "IBUIView":
			generateUIView(val);
			break;
		    default:
			trace("#skip", val.obj);
			break;
		    }
		}
	    }
	}

	/**
	 * dump data (for debug only)
	 */
	public static function dump():void {
	    for each (var val:* in _genCode) {
		trace(val.name + ":");
		trace(val.code);
	    }
	}

	public static function trim(name:String):String {
	    var trim:Array = name.split(' ');
	    return trim.join("_");
	}

	/**
	 * cleanup the code generator
	 */
	public static function cleanup():void {
	    _genCode = new Array();
	}

	/**
	 * Get generated code
	 */
	public static function getGeneratedCode():Array {
	    return _genCode;
	}

	/**
	 * generate UIWindow
	 */       
	private static function generateUIWindow(val:Object):String {
	    trace("generate UIWindow", val.name, val.id);
	    var result:Object;
	    var _objName:String;

	    if (val.subviews.length == 0) {
		//trace("no subview");
		return null;
	    }

	    _appJs.code += "(function() {\n";
	    if (val.name != "") {
		result = createFile("ui/" + val.name + ".js");
		_objName = val.name;
		_appJs.code += "  var " + _objName + " = require('ui/" + _objName + "');\n";
		_appJs.code += "  // new " + _objName + "().open();\n";
		_appJs.code += "  return new " + _objName + "(); /* uncomment above and remove this in real application */\n";
		result.code += "function " + _objName + "() {\n";
		result.code += "  var self = Ti.UI.createWindow();\n";
		result.code += createSubviews("self", val.subviews);
		result.code += "  return self;\n";
		result.code += "}\n";
		result.code += "module.exports = " + _objName + ";\n";
	    } else {
		_objName = "win" + _id++;
		_appJs.code += "var " + _objName + " = Titanium.UI.createWindow();\n\n";
		result = getFile("app.js");
		result.code += createSubviews(_objName, val.subviews);
		result.code += "// " + _objName + ".open();\n";
		result.code += "return " + (val.name != "" ? "new " + _objName + "()" : _objName) + "; /* uncomment above and remove this in real application */\n";
	    }
	    _appJs.code += "}());\n";
	    return _objName;
	}

	/**
	 * generate UITabBarController
	 */
	private static function generateUITabBarController(val:Object):String {
	    trace("generate UITabBarController", val.name, val.id);
	    var _objName:String;
	    var result:Object;

	    _appJs.code += "(function() {\n";

	    if (val.name != "") {
		_objName = val.name;
	    } else {
		_objName = "tabGroup" + _id++;
	    }
	    _appJs.code += "var " + _objName + " = Titanium.UI.createTabGroup();\n\n";

	    for each (var view:* in val.views) {
		var child:String;
		switch(view.obj) {
		case "IBUIViewController":
		    child = generateUIViewController(view, false);
		    break;
		case "IBUINavigationController":
		    child = generateUINavigationController(view, false);
		    break;
		case "IBUITableViewController":
		    child = generateUITableViewController(view, false);
		    break;
		case "IBUIImagePickerController":
		    child = generateUIImagePickerController(view, false);
		    break;
		default:
		    // do nothing
		    trace("#skip", view.obj);
		    break;
		}
		if (child != null) {
		    var _tabName:String;
		    if (view.hasOwnProperty("tabItem")) {
			_tabName = view.tabItem.title;
		    } else {
			_tabName = "tab" + _id++;
		    }
		    _appJs.code += "var " + trim(_tabName) + " = Titanium.UI.createTab({\n";
		    _appJs.code += "    title: '" + _tabName + "',\n";
		    _appJs.code += "    window: " + child + "\n";
		    _appJs.code += "});\n";
		    _appJs.code += (_objName + ".addTab(" + trim(_tabName) + ");\n\n");
		}
	    }

	    _appJs.code += "// " + _objName + ".open();\n";
	    _appJs.code += "return " + _objName + "; /* uncomment above and remove this in real application */\n";

	    _appJs.code += "}());\n";

	    return _objName;
	}

	/**
	 * generate UIViewController
	 */
	private static function generateUIViewController(val:Object, isRoot:Boolean = true):String {
	    if (val == null)
		return null;

	    trace("generate UIViewController", val.name, val.id);
	    var result:Object;
	    var _objName:String;

	    if (val.name != "") {
		result = createFile("ui/" + val.name + ".js");
		_objName = val.name;
		_appJs.code += "var " + _objName + " = require('ui/" + _objName + "');\n";
		result.code += "function " + _objName + "() {\n";
		result.code += "var self = Titanium.UI.createWindow();\n";
	    } else {
		_objName = "win" + _id++;
		_appJs.code += "var " + _objName + " = Titanium.UI.createWindow();\n";
		result = getFile("app.js");
	    }

	    if (val.navItem != null) {
		result.code += (val.name != "" ? "self" : _objName) + ".title = '" + val.navItem.title + "';\n";
	    } else {		
		result.code += (val.name != "" ? "self" : _objName) + ".title = null;\n";
		result.code += (val.name != "" ? "self" : _objName) + ".navBarHidden = true;\n";
	    }
	    result.code += "\n";

	    result.code += createView((val.name != "" ? "self" : _objName), val.view);

	    if (val.name != "") {
		result.code += "return self;\n";
		result.code += "}\n";
		result.code += "module.exports = " + _objName + ";\n";
	    }

	    return (val.name != "" ? "new " + _objName + "()" : _objName);
	}

	/**
	 * generate UINavigationController
	 */
	private static function generateUINavigationController(val:Object, isRoot:Boolean = true):String {
	    if (val == null)
		return null;

	    trace("generate UINavigationController", val.name, val.id);
	    var result:Object;
	    var _objName:String;
	    var _winName:String;

	    _appJs.code += "(function() {\n";
	    if (val.name != "") {
		_objName = val.name;
	    } else {
		_objName = "ApplicationNavWindow";
	    }
	    _winName = "ApplicationWindow";
	    _appJs.code += "var " + _objName + " = Titanium.UI.createWindow();\n";
	    _appJs.code += "var " + _winName + " = require('ui/" + _winName + "');\n";
	    result = createFile("ui/ApplicationWindow.js");
	    result.code += "function " + _winName + "() {\n";
	    result.code += "  var self = Ti.UI.createWindow();\n";

	    trace("views=", val.views.length);
	    var _viewName:String;
	    for each (var view:* in val.views) {
		switch(view.obj) {
		case "IBUIViewController":
		    if (view.name == "") {
			_viewName = "view" + _id++;
		    } else {
			_viewName = view.name;
		    }
		    result.code += "var " + _viewName + " = Titanium.UI.createView();\n\n";
		    result.code += createView(_viewName, view.view);
		    break;
		case "IBUITableViewController":
		    if (view.name == "") {
			_viewName = "tbl" + _id++;
		    } else {
			_viewName = view.name;
		    }
		    result.code += "var " + _viewName + "_rows = [\n";
		    result.code += "    {title:'Row 1', hasChild:false},\n";
		    result.code += "    {title:'Row 2', hasChild:false},\n";
		    result.code += "    {title:'Row 3', hasChild:false}\n";
		    result.code += "];\n";
		    result.code += "\n";
		    result.code += "var " + _viewName + " = Titanium.UI.createTableView({\n";
		    result.code += "    data: " + _viewName + "_rows\n";
		    result.code += "});\n";
		    break;
		case "UIImagePickerController":
		    trace("UIImagePickerController not supported yet");
		    break;
		}
		result.code += "self.add(" + _viewName + ");\n";
		if (view.hasOwnProperty("navItem")) {
		    if (view.navItem != null) {
			result.code += "self.title = '" + view.navItem.title + "';\n";
		    } else {		
			result.code += "self.title = null;\n";
			result.code += "self.navBarHidden = true;\n";
		    }
		}
		result.code += "return self;\n";
		result.code += "};\n";
		result.code += "module.exports = " + _winName + ";\n";
	    }

	    var _navName:String = "navGroup";
	    _appJs.code += "var " + _navName + " = Titanium.UI.iPhone.createNavigationGroup({\n";
	    _appJs.code += "    window: new ApplicationWindow()\n";
	    _appJs.code += "});\n";
	    _appJs.code += _objName + ".add(" + _navName + ");\n\n";
	    
	    _appJs.code += "// " + _objName + ".open();\n";
	    _appJs.code += "return " + _objName + "; /* uncomment above and remove this in real application */\n";
	    _appJs.code += "}());\n";

	    return _objName;
	}

	/**
	 * generate UITableViewController
	 */
	private static function generateUITableViewController(val:Object, isRoot:Boolean = true):String {
	    if (val == null)
		return null;

	    trace("generate UITableViewController", val.name, val.id);
	    var result:Object;
	    var _objName:String;
	    if (isRoot) {
		_appJs.code += "/*\n";
	    }
	    if (val.name != "") {
		result = createFile("ui/" + val.name + ".js");
		_objName = val.name;
		_appJs.code += "var " + _objName + " = Titanium.UI.createWindow({\n";
		_appJs.code += "    url: '" + _objName + ".js" + "'\n";
		_appJs.code += "});\n\n";
		result.code += "var " + _objName + " = Titanium.UI.currentWindow;\n\n";
	    } else {
		result = getFile("app.js");
		_objName = "win" + _id++;
		_appJs.code += "var " + _objName + " = Titanium.UI.createWindow();\n\n";
	    }
	    result.code += "var " + _objName + "_rows = [\n";
	    result.code += "    {title:'Row 1', hasChild:false, test:''},\n";
	    result.code += "    {title:'Row 2', hasChild:false, test:''},\n";
	    result.code += "    {title:'Row 3', hasChild:false, test:''}\n";
	    result.code += "];\n";
	    result.code += "\n";
	    result.code += "var " + _objName + "_view = Titanium.UI.createTableView({\n";
	    result.code += "    data: " + _objName + "_rows\n";
	    result.code += "});\n";
	    result.code += _objName + ".add(" + _objName + "_view" + ");\n\n";
	    result.code += _objName + ".addEventListener('click', function(e)\n";
	    result.code += "{\n";
	    result.code += "    if (e.rowData.hasChild && e.rowData.test) {\n";
	    result.code += "        var win = Titanium.UI.createWindow({\n";
	    result.code += "            title: e.rowData.title,\n";
	    result.code += "            url: e.rowData.test\n";
	    result.code += "        });\n";
	    result.code += "        Titanium.UI.currentTab.open(win, {animated:true});\n";
	    result.code += "    }\n";
	    result.code += "});\n";
	    if (isRoot) {
		result.code += "// Uncomment the following to display the window\n";
		result.code += "// " + _objName + ".open();\n";
	    }
	    if (isRoot) {
		_appJs.code += "*/\n";
	    }
	    return _objName;
	}

	/**
	 * generate UIImagePickerController
	 */
	private static function generateUIImagePickerController(val:Object, isRoot:Boolean = true):String {
	    if (val == null)
		return null;

	    trace("generate UIImagePickerController", val.name, val.id);
	    var result:Object;
	    var _objName:String;

	    // not supported yet
	    return "";

	}

	/**
	 * generate UISplitViewController
	 */
	private static function generateUISplitViewController(val:Object):String {
	    trace("generate UISplitViewController", val.name, val.id);
	    var _objName:String;
	    if (val.name != "") {
		_objName = val.name;
	    } else {
		_objName = "splitWin" + _id++;
	    }

	    var _subView:Array = ["masterView: ", "detailView: "];
	    var i:uint = 0;
	    for each (var view:* in val.views) {
		var child:String;
		switch(view.obj) {
		case "IBUIViewController":
		    child = generateUIViewController(view, false);
		    break;
		case "IBUINavigationController":
		    child = generateUINavigationController(view, false);
		    break;
		case "IBUITableViewController":
		    child = generateUITableViewController(view, false);
		    break;
		case "IBUIImagePickerController":
		    child = generateUIImagePickerController(view, false);
		    break;
		default:
		    // do nothing
		    trace("#skip", view.obj);
		    break;
		}
		if (child != null) {
		    if (i == 0) {
			_subView[0] += child + ",\n";
			i++;
		    } else if (i == 1) {
			_subView[1] += child + "\n";
			i++;
		    }
		}
	    }

	    _appJs.code += "var " + _objName + " = Titanium.UI.iPad.createSplitWindow({\n";
	    _appJs.code += "    " + _subView[0];
	    _appJs.code += "    " + _subView[1];
	    _appJs.code += "});\n\n";

	    _appJs.code += _objName + ".open();\n\n";

	    return _objName;
	}

	/**
	 * generate UITableViewCell
	 */
	private static function generateUITableViewCell(val:Object):String {
	    if (val == null)
		return null;

	    trace("generate UITableViewCell", val.name, val.id);
	    var result:Object;
	    var _objName:String;

	    if (val.name != "") {
		_objName = val.name;
	    } else {
		_objName = "row" + _id++;
	    }

	    var _rowName:String = "rowData" + _id++;

	    _appJs.code += "// Custom TableViewCell\n";
	    _appJs.code += "var " + _rowName + " = []\n";
	    _appJs.code += "for (var r = 1; r < n; r++) { // Specify row count (n)\n";
	    _appJs.code += "var " + _objName + " = Titanium.UI.createTableViewRow({\n";
	    _appJs.code += createProperties(val.properties);
	    _appJs.code += "});\n\n";
	    _appJs.code += createSubviews(_objName, val.subviews);
	    _appJs.code += _rowName + ".push(" + _objName + ");\n";
	    _appJs.code += "}\n\n";
	    _appJs.code += "var tableView" + _id++ + " = Titanium.UI.createTableView({\n";
	    _appJs.code += "    data: " + _rowName + "\n";
	    _appJs.code += "});\n\n";
	    return _objName;
	}

	/**
	 * generate UIView
	 */
	private static function generateUIView(val:Object):String {
	    if (val == null)
		return null;

	    trace("generate UIView", val.name, val.id);
	    var result:Object;
	    var _objName:String;

	    if (val.name != "") {
		_objName = val.name;
	    } else {
		_objName = "view" + _id++;
	    }

	    _appJs.code += "// Custom View\n";
	    _appJs.code += "var " + _objName + " = Titanium.UI.createView({\n";
	    _appJs.code += createProperties(val.properties);
	    _appJs.code += "});\n\n";
	    if (val.subviews.length != 0) {
		_appJs.code += createSubviews(_objName, val.subviews);
	    }
	    return _objName;
	}

	/**
	 * create subviews
	 */
	private static function createSubviews(parent:String, subviews:Array):String {
	    var result:String = "";
	    for each (var val:* in subviews) {
		result += createView(parent, val);
	    }
	    return result;
	}

	/**
	 * generate views
	 */
	private static function createView(parent:String, view:Object):String {
	    if (view == null)
		return "";

	    trace("createView", view.obj);
	    var result:String = "";
	    var _viewName:String;
	    switch(view.obj) {
	    case "IBUIActivityIndicatorView":
		if (view.name == "") {
		    _viewName = "actInd" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.UI.createActivityIndicator({\n";
		result += createProperties(view.properties, true);
		result += "// Chose style of the ActivityIndicator from the following\n";
		result += "//    style: Titanium.UI.iPhone.ActivityIndicatorStyle.PLAIN\n";
		result += "    style: Titanium.UI.iPhone.ActivityIndicatorStyle.DARK\n";
		result += "//    style: Titanium.UI.iPhone.ActivityIndicatorStyle.BIG\n";
		result += "});\n";
		break;
	    case "IBUIButton":
		if (view.name == "") {
		    _viewName = "button" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.UI.createButton({\n";
		result += createProperties(view.properties);
		result += "});\n";
		result += _viewName + ".addEventListener('click', function()\n";
		result += "{\n";
		result += "    // write the code here\n";
		result += "});\n";
		break;
	    case "IBUIImageView":
		if (view.name == "") {
		    _viewName = "imageView" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.UI.createImageView({\n";
		result += createProperties(view.properties);
		result += "});\n";
		break;
	    case "IBUILabel":
		if (view.name == "") {
		    _viewName = "l" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.UI.createLabel({\n";
		result += createProperties(view.properties);
		result += "});\n";
		break;
	    case "IBMKMapView":
		if (view.name == "") {
		    _viewName = "mapView" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.Map.createView({\n";
		result += createProperties(view.properties);
		result += "});\n";
		break;
	    case "IBUIDatePicker":
	    case "IBUIPickerView":
		if (view.name == "") {
		    _viewName = "picker" + _id++;
		} else {
		    _viewName = view.name;
		}		
		result += "var " + _viewName + " = Titanium.UI.createPicker({\n";
		result += createProperties(view.properties);
		result += "});\n";
		result += _viewName + ".selectionIndicator = true;\n";
		if (view.obj == "IBUIPickerView") {
		    result += _viewName + ".type = Titanium.UI.PICKER_TYPE_PLAIN;\n";
		    result += "var " + _viewName + "_data = [];\n";
		    result += _viewName + "_data[0] = Titanium.UI.createPickerRow({title:'Bananas', custom_item:'b'});\n";
		    result += _viewName + "_data[1] = Titanium.UI.createPickerRow({title:'Strawberries', custom_item:'s'});\n";
		    result += _viewName + "_data[2] = Titanium.UI.createPickerRow({title:'Mangos', custom_item:'m'});\n";
		    result += _viewName + "_data[3] = Titanium.UI.createPickerRow({title:'Grapes', custom_item:'g'});\n";
		    result += _viewName + ".add(" + _viewName + "_data);\n";
		} else {
		    result += _viewName + ".type = Titanium.UI.PICKER_TYPE_DATE_AND_TIME;\n";
		}
		break;
	    case "IBUIProgressView":
		if (view.name == "") {
		    _viewName = "ind" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.UI.createProgressBar({\n";
		result += "//    min: 0.0,\n";
		result += "//    max: 1.0,\n";
		result += createProperties(view.properties, true);
		result += "    style:Titanium.UI.iPhone.ProgressBarStyle.PLAIN\n";
		result += "});\n";
		result += "// Uncomment the following to display the progress bar\n";
		result += "// " + _viewName + ".show();\n";
		break;		
	    case "IBUIScrollView":
		if (view.name == "") {
		    _viewName = "scrollView" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.UI.createScrollView({\n";
		//result += createProperties(view.properties);
		result += "    contentWidth: 'auto',\n";
		result += "    contentHeight: 'auto'\n";
		result += "});\n";
		if (view.subviews.length != 0) {
		    result += createSubviews(_viewName, view.subviews);
		} else {
		    var scrollchildview:String = "view" + _id++;
		    result += "var " + scrollchildview + " = Titanium.UI.createView({\n";
		    result += "    backgroundColor: '#ffffff'\n";
		    result += "});\n";
		    result += _viewName + ".add(" + scrollchildview + ");\n\n";
		}
		break;
	    case "IBUISearchBar":
		if (view.name == "") {
		    _viewName = "search" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.UI.createSearchBar({\n";
		result += "    top:0,\n";
		result += createProperties(view.properties);
		result += "});\n";
		break;				
	    case "IBUISegmentedControl":
		if (view.name == "") {
		    _viewName = "buttonBar" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.UI.createButtonBar({\n";
		result += createProperties(view.properties);
		result += "});\n";
		break;				
	    case "IBUISlider":
		if (view.name == "") {
		    _viewName = "slider" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.UI.createSlider({\n";
		result += createProperties(view.properties);
		result += "});\n";
		break;				
	    case "IBUISwitch":
		if (view.name == "") {
		    _viewName = "s" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.UI.createSwitch({\n";
		result += createProperties(view.properties);
		result += "});\n";
		break;
	    case "IBUITableView":
		if (view.name == "") {
		    _viewName = "tableView" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + "_rows = [\n";
		result += "    {title:'Row 1', hasChild:false, test:''},\n";
		result += "    {title:'Row 2', hasChild:false, test:''},\n";
		result += "    {title:'Row 3', hasChild:false, test:''}\n";
		result += "];\n";
		result += "\n";
		result += "var " + _viewName + " = Titanium.UI.createTableView({\n";
		result += createProperties(view.properties, true);
		result += "    data: " + _viewName + "_rows\n";
		result += "});\n";
		result += _viewName + ".addEventListener('click', function(e)\n";
		result += "{\n";
		result += "    if (e.rowData.hasChild && e.rowData.test) {\n";
		result += "        var win = require(\"'ui/\" + e.rowData.test + \"'\").open();\n";
		result += "        win.title = e.rowData.title;\n";
		result += "        win.open({animated:true});\n";
		result += "    }\n";
		result += "});\n";
		break;
	    case "IBUITextField":
		if (view.name == "") {
		    _viewName = "tf" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.UI.createTextField({\n";
		result += "    borderStyle: Titanium.UI.INPUT_BORDERSTYLE_ROUNDED,\n";
		result += createProperties(view.properties);
		result += "});\n";
		break;
	    case "IBUITextView":
		if (view.name == "") {
		    _viewName = "ta" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.UI.createTextArea({\n";
		result += createProperties(view.properties);
		result += "});\n";
		break;
	    case "IBUIToolbar":
		if (view.name == "") {
		    _viewName = "toolbar" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += parseToolbarItems(view.properties);
		result += "var " + _viewName + " = Titanium.UI.createToolbar({\n";
		result += createProperties(view.properties);
		result += "});\n";
		break;
	    case "IBUIView":
		if (view.name == "") {
		    _viewName = "view" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.UI.createView({\n";
		result += createProperties(view.properties);
		result += "});\n\n";
		if (view.subviews.length != 0) {
		    result += createSubviews(_viewName, view.subviews);
		}
		break;
	    case "IBUIWebView":
		if (view.name == "") {
		    _viewName = "webView" + _id++;
		} else {
		    _viewName = view.name;
		}
		result += "var " + _viewName + " = Titanium.UI.createWebView({\n";
		result += "    url: 'http://www.google.co.jp/',\n";
		result += createProperties(view.properties);
		result += "});\n";
		break;
	    case "NSSubviews":
		result += createSubviews(parent, view.subviews);
		break;
	    default:
		trace("# skip", view.obj);
		break;
	    }
	    if (_viewName != null) {
		result += parent + ".add(" + _viewName + ");\n\n";
	    }
	    return result;
	}

	/**
	 * create properties
	 */
	private static function createProperties(properties:Object, hasNext:Boolean = false):String {
	    var result:String = "";
	    for each (var property:* in properties) {
		if (property.hasOwnProperty("type")) {
		    switch(property.type) {
		    case "frame":
			result += parseFrame(property.value);
			break;
		    case "framesize":
			result += parseFrameSize(property.value);
			break;
		    case "text":
			result += parseText(property.value);
			break;
		    case "value":
		    case "min":
		    case "max":
			result += parseValue(property.value, property.type);
			break;
		    case "title":
			result += parseTitle(property.value);
			break;
		    case "font":
			result += parseFont(property.value);
			break;
		    case "labels":
			result += parseLabels(property.value);
			break;
		    case "toolbar":
			result += parseToolbar(property.value);
			break;
		    case "color":
			result += parseColor(property.value);
			break;
		    case "backgroundColor":
			result += parseColor(property.value, true);
			break;
		    default:
			trace("#unknown type", property.type);
			break;
		    }
		} else {
		    trace("#unknow property");
		    for (var val:* in property) {
			trace(val);
		    }
		}
	    }
	    if (!hasNext) {
		result = result.substring(0, result.length - 2) + "\n";
	    }
	    return result;
	}

	/**
	 * frame
	 */
	private static function parseFrame(value:String):String {
	    trace("parse Frame", value);
	    var result:String = "";
	    value = value.substring(1, value.length - 1);
	    trace(value);
	    var _sizepos:Array = value.split(", ");	    
	    result += "    left: " + _sizepos[0].substring(1) + ",\n";
	    result += "    top: " + _sizepos[1].substring(0, _sizepos[1].length - 1) + ",\n";
	    result += "    width: " + _sizepos[2].substring(1) + ",\n";
	    result += "    height: " + _sizepos[3].substring(0, _sizepos[3].length - 1) + ",\n";
	    trace(result);
	    return result;
	}

	/**
	 * framesize
	 */
	private static function parseFrameSize(value:String):String {
	    trace("parse FrameSize", value);
	    var result:String = "";	    
	    value = value.substring(1, value.length - 1);
	    trace(value);
	    var _size:Array = value.split(", ");
	    trace(_size.length);
	    result += "    width: " + _size[0] + ",\n";
	    result += "    height: " + _size[1] + ",\n";
	    trace(result);
	    return result;
	}

	/**
	 * text
	 */
	private static function parseText(value:String):String {
	    trace("parse Text", value);
	    var result:String = "";
	    result += "    text: '" + value + "',\n";
	    trace(result);
	    return result;
	}

	/**
	 * value
	 */
	private static function parseValue(value:String, type:String):String {
	    trace("parse Value", value);
	    var result:String = "";
	    result += "    " + type + ": " + value + ",\n";
	    trace(result);
	    return result;
	}
	
	/**
	 * title
	 */
	private static function parseTitle(value:String):String {
	    trace("parse Title", value);
	    var result:String = "";
	    result += "    title: '" + value + "',\n";
	    trace(result);
	    return result;
	}

	/**
	 * font
	 */
	private static function parseFont(value:String):String {
	    trace("parse Font", value);
	    var result:String = "";
	    var _font:Array = value.split(",");
	    result += "    font: {fontFamily: '" + _font[0] + "', fontSize: " + _font[1] + "},\n";
	    return result;
	}
	
	/**
	 * labels
	 */
	private static function parseLabels(value:String):String {
	    trace("parse Labels", value);
	    var result:String = "";
	    result += "    labels: " + value + ",\n";
	    return result;
	}

	/**
	 * toolbar items
	 */
	private static function parseToolbarItems(properties:Object):String {
	    var result:String = "";
	    for each (var property:* in properties) {
		if (property.hasOwnProperty("type")) {
		    switch(property.type) {
		    case "toolbar":
			result = parseToolbar(property.value, false);
			break;
		    default:
			// do nothing
			break;
		    }
		}
	    }
	    return result;
	}

	/**
	 * toolbar
	 */
	private static function parseToolbar(value:String, isProperty:Boolean = true):String {
	    trace("parse Toolbar", value);
	    var result:String = "";
	    var _flex_created:Boolean = false;
	    var _fix_created:Boolean = false;
	    value = value.substring(1, value.length - 1);
	    var _values:Array = value.split("}, ");
	    for each (var _value:String in _values) {
		_value = _value.substring(1, _value.length);
		var last:int = _value.search("}");
		if (last >= 0)
		    _value = _value.substring(0, last - 1);
		var _items:Array = _value.split(", ");
		for each (var _item:String in _items) {
		    var _title:String = "";
		    var _id:String = "";
		    var _width:String = "";
		    var _obj:Array = _item.split(": ");
		    switch (String(_obj[0])) {
		    case "title":
			_title = (_obj.length == 2 ? _obj[1] : "");
			break;
		    case "id":
			_id = (_obj.length == 2 ? _obj[1] : "");
			break;
		    case "width":
			_width = (_obj.length == 2 ? _obj[1] : "");
			break;
		    default:
			trace("#skip", _obj[0]);
			break;
		    }
		    if (isProperty) {
			if (_title != "") {
			    result += _title + ", ";
			} else if (_id == "5") {
			    result += "_flexible_space, ";
			} else if (_id == "6") {
			    // not supported yet?
			    //result += "_fixed_space, ";
			}
		    } else {
			if (_title != "") {
			    result += "var " + _title + " = Titanium.UI.createButton({\n";
			    result += "    title: '" + _title + "',\n";
			    result += "    style: Titanium.UI.iPhone.SystemButtonStyle.DONE\n";
			    result += "});\n";
			    result += _title + ".addEventListener('click', function()\n";
			    result += "{\n";
			    result += "    // write the code here\n";
			    result += "});\n\n";
			} else if (_id == "5") {
			    if (!_flex_created) {
				result += "var _flexible_space = Titanium.UI.createButton({\n";
				result += "    systemButton: Titanium.UI.iPhone.SystemButton.FLEXIBLE_SPACE\n";
				result += "});\n\n";
				_flex_created = true;
			    }
			} else if (_id == "6") {
			    if (!_fix_created) {
				result += "// Not supported yet?\n";
				result += "//var _fixed_space = Titanium.UI.createButton({\n";
				result += "//    width: " + _width + ", \n";
				result += "//    systemButton: Titanium.UI.iPhone.SystemButton.FIXED_SPACE\n";
				result += "//});\n\n";
				_fix_created = true;
			    }
			}
		    }
		}
	    }
	    return ( isProperty ? "    items: [" + result.substring(0, result.length - 2) + "],\n" : result);
	}

	/**
	 * color
	 */
	private static function parseColor(value:String, isBackground:Boolean = false):String {
	    trace("parse Color", value);
	    var _color:Array = value.split(":");
	    var result:String = "";
	    result += "    " + (isBackground ? "backgroundColor: '" : "color: '") + _color[0] + "',\n";
	    if (_color.length > 1) {
	    result += "    opaque: " + _color[1] + ",\n";
	    }
	    return result;
	}
	
	/**
	 * create new JavaScript file
	 */  
	private static function createFile(filename:String):Object {
	    var result:Object;
	    result = getFile(filename);
	    if (result == null) {
		result = {name:filename, code:new String()};
		_genCode.push(result);
	    }
	    return result;
	}

	/**
	 * get JavaScript file
	 */
	private static function getFile(filename:String):Object {
	    for each (var val:* in _genCode) {
		if (val.name == filename) {
		    return val;
		}
	    }
	    return null;
	}
    }
}
