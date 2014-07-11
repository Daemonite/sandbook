<cfscript>
//s3path = "s3://AKIAJE56WYVFJHCXQKIQ:GLvmJxAEzh9fiHI3pG9lrGaty1ex3WoW3KSBtU4p@s3.amazonaws.com/autodoc-test/test.txt";
//s3path = "/autodoc-test/test.txt";
//writeOutput(getDirectoryFromPath(s3path) & "<br>");
//writeOutput(directoryExists(getDirectoryFromPath(s3path)) & "<br>");
//if (not directoryExists(getDirectoryFromPath(s3path)))
//	directory action="create" directory="#getDirectoryFromPath(s3path)#" mode="777";
file action="write" file="/autodoc-test/test.txt" output="test";
</cfscript>