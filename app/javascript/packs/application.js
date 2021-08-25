// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import '../src/style.scss';
import '../src/css/icofont.min.css';
import '../src/css/LineIcons.css';
import '../src/css/viewer.min.css';

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")
require("jquery")
require("popper.js").default
require("bootstrap")
require("feather-icons")
require("packs/viewer.min")
require("@nathanvda/cocoon")
require("packs/custom")
require("select2")

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)