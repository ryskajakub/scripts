let config: < default: < password: string ; name: string ; > Js.t > Js.t = [%bs.raw {| require(process.env['HOME'] + "/.config/scripts/config.js") |}]
