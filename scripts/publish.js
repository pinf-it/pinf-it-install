
const PATH = require("path");
const PINF = require("pinf").for(module);
const KNOX = require("knox");


exports.main = function(callback) {

	var config = PINF.config();

	function getCredentials(callback) {
		return PINF.sm(function(err, SM) {
			if (err) return callback(err);

			return SM.getCredentials(["github.com/sourcemint/sm-plugin-sm/0", "s3"]).then(function(credentials) {
				return callback(null, credentials);
			}).fail(callback);
		});
	}

	function uploadFile(client, fromPath, toPath, callback) {

        console.log("Uploading '" + fromPath + "' to '" + "http://s3.sourcemint.org/" + toPath + "'");

        return client.headFile(toPath, {
            "Content-Type": "application/x-gzip",
            "x-amz-acl": "public-read"
        }, function(err, res) {
            if (err) return callback(err);
            if (res.statusCode === 200) return callback(null);
            client.putFile(fromPath, toPath, {
                "Content-Type": "application/x-gzip",
                "x-amz-acl": "public-read"
            }, function(err, res) {
                if (err) return callback(err);
                if (res.statusCode === 200) return callback(null);
                var response = "";
                res.on("data", function(chunk) {
                    response += chunk.toString();
                });
                return callback(new Error("Got status code '" + res.statusCode + "' with message: " + response));
            });
        });
	}

	return getCredentials(function(err, credentials) {
		if (err) return callback(err);

		console.log("Uploading files ...");

        var client = KNOX.createClient(credentials);

		return uploadFile(
			client,
			config.pinf.packages["node-osx-64"].archive,
			PATH.join(config.pinf.uid, "-archives", PATH.basename(config.pinf.packages["node-osx-64"].archive)),
		function(err) {
			if (err) return callback(err);

			console.log("Done!");
			return callback(null);
		});
	});
}


if (require.main === module) {
	PINF.run(exports.main);
}
