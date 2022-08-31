
const webpack = require('webpack')

module.exports = {
    module: {
        rules: [
          {
            test: /\.scss$/i,
            use: ["postcss-loader", "sass-loader"],
          },
        ],
      },
    resolve: {
        alias: {
            $: 'jquery/src/jquery',
            jQuery: 'jquery/src/jquery',
            jquery: 'jquery'
        }
    },
    plugins: [
        new webpack.ProvidePlugin({
            $: 'jquery/src/jquery',
            jQuery: 'jquery/src/jquery'
        })
    ],
    // Eliminate CORS issue
    // devServer: {
    //     host: 'localhost',
    //     port: 3000
    // }
}