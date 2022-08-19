const { environment } = require('@rails/webpacker')

const webpack = require('webpack')
environment.plugins.prepend('Provide',
  new webpack.ProvidePlugin({
    $: 'jquery/src/jquery',
    jQuery: 'jquery/src/jquery'
  })
)

// Get the actual sass-loader config
const sassLoader = environment.loaders.get('sass')
const sassLoaderConfig = sassLoader.use.find(function (element) {
return element.loader == 'sass-loader'
})

// try to fix path
const dotenv = require('dotenv');
const dotenvFiles = ['.env.local','.env.${process.env.NODE_ENV}','.env']
dotenvFiles.forEach((dotenvFile) => {dotenv.config({ path: dotenvFile, silent: true })});

environment.loaders.get('file').use.find(item => item.loader === 'file-loader').options.publicPath = (process.env.RELATIVE_URL_ROOT || '') + '/packs';


// Use Dart-implementation of Sass (default is node-sass)
const options = sassLoaderConfig.options
options.implementation = require('sass')




function hotfixPostcssLoaderConfig (subloader) {
  const subloaderName = subloader.loader
  if (subloaderName === 'postcss-loader') {
    subloader.options.postcssOptions = subloader.options.config
    delete subloader.options.config
  }
}

environment.loaders.keys().forEach(loaderName => {
  const loader = environment.loaders.get(loaderName)
  loader.use.forEach(hotfixPostcssLoaderConfig)
})

module.exports = environment
