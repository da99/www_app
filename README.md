
Disclaimer:
-----------

Not ready yet for human consumption.


Install & Use
------------

    npm install ok_slang

    var Ok = require('ok_slang').Ok;
    Ok.to_html({form: [
      ["text_box", "my_name", "INPUT YOUR NAME", "one line"]
    ]});

    // --> outputs:
    //    <form>
    //       <input type="text" name="my_name">INPUT YOUR NAME</input>
    //    </form>
