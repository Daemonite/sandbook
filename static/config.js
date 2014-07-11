require.config({
  "baseUrl" : "/static/app",
  "paths"   : {
    "jquery"         : "/static/jquery-1.11.0/jquery.min",
    "pietimer"       : "/static/pietimer/jquery.pietimer",
    "underscore"     : "/static/underscore-1.6.0/underscore",
    "backbone"       : "/static/backbone-1.1.2/backbone",
    "react"          : "/static/react-0.10.0/react-with-addons",
    "bootstrap"      : "/static/bootstrap-3.1.1-dist/js/bootstrap.min",
    "JSXTransformer" : "/static/JSXTransformer-0.10.0/JSXTransformer"
  },
  "shim" : {
    "backbone" : {
      "deps" : [
        "jquery",
        "underscore"
      ],
      "exports" : "Backbone"
    },
    "jquery" : {
      "exports" : "$"
    },
    "underscore" : {
      "exports" : "_"
    },
    "bootstrap" : {
      "deps" : [
      	"jquery"
      ]
    }
  },
  "jsx" : {
    "fileExtension" : ".jsx"
  }
});