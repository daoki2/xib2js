/**
 * The File Utility Class for ActionScript 3.0
 *
 * @author      Copyright (c) 2008 daoki2
 * @version     1.0.1
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
    import flash.filesystem.File;
    import flash.filesystem.FileStream;
	
	/**
	 * ファイル操作を行うためのユーティリティクラスです <span style="color:#FF0000; font-weight:bold;">(AIR Only)</span>
	 */
    public class FileUtil {

       /**
        * Constructor
		* @private
        */
        public function FileUtil() {
            throw new IllegalOperationError("FileUtil class can not create instance");
        }

       /**
        * Get the line count of the file
        * @param	filestream	The filestream to count
        * @return			The line count of the specified file
        */
        public static function getLineCount(filestream:FileStream):Number {
            var result:Number = 0;
            var skip:Number;
            while(filestream.bytesAvailable > 0) {
                skip = getLineEnd(filestream);
                result++;
            }
            filestream.position = 0;
            return result;
        }

       /**
        * Read line from the file
        * @param	filestream	The filestream to read
        * @return			The line of the specified file
        */
        public static function readln(filestream:FileStream):String {
            var result:String = new String();
            var startpos:Number = filestream.position;
            var skip:Number = getLineEnd(filestream);
            var len:Number = filestream.position - startpos - skip;
            filestream.position = startpos;
            result = filestream.readUTFBytes(len);
            filestream.position += skip;
            return result;
        }

       /**
        * private method
        */

       /**
        * Move the file pointer to the end of the line
        */
        private static function getLineEnd(filestream:FileStream):Number {
            var skip:Number = 0;
            var code:int;
            while(filestream.bytesAvailable > 0) {
                code = filestream.readByte();
                if (code == 0x0A) {
                    skip = 1;
                    break;
                }
                if (code == 0x0D) {
                    skip = 1;
                    if (filestream.bytesAvailable > 0) {
                        code = filestream.readByte();
                        if (code != 0x0A) {
                            filestream.position -= 1;
                        } else {
                            skip = 2;
                        }
                        break;
                    } else
                        break;
                }
            }
            return skip;
        }
    }
}
