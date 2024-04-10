// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let Hooks = {
    'watch_input': {
        mounted() {
            this.el.addEventListener('input', (e) => {
                this.pushEvent(this.el.getAttribute('data-event'), {value: e.target.value});
            });
        },
    },
    'watch_arg': {
        mounted() {
            this.el.addEventListener('input', (e) => {
                this.pushEvent(this.el.getAttribute('data-event'), {index: this.el.getAttribute('data-index'), value: e.target.value});
            });
        },
    },
    'change_code': {
        mounted() {
            this.el.addEventListener('input', (e) => {
                this.pushEvent('code_change', {value: e.target.value});
            });
        },
    },
    "update_chain_arg": {
        mounted() {
            this.el.addEventListener('input', (e) => {
                this.pushEvent('update_chain_arg', {
                    chain_index: this.el.getAttribute('data-chain_index'),
                    arg_index: this.el.getAttribute('data-arg_index'),
                    value: e.target.value,
                });
            });
        },
    },
    "change_runner_arg": {
        mounted() {
            this.el.addEventListener('input', (e) => {
                this.pushEvent('change_runner_arg', {
                    hash: this.el.getAttribute('data-hash'),
                    index: this.el.getAttribute('data-index'),
                    value: e.target.value,
                });
            });
        },
    },
    "update_node": {
        mounted() {
            const kind = this.el.getAttribute('data-kind');
            const path = this.el.getAttribute('data-path');
            if (kind === 'bool') {
                this.el.addEventListener('change', () => {
                    this.pushEvent('change_path', {path, value: this.el.checked});
                });
            } else {
                this.el.addEventListener('change', () => {
                    this.pushEvent('change_path', {path, value: this.el.value});
                });
            }
        }
    },
};
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks});

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())


// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

