import webpack from 'webpack';
import path from 'path';
import HtmlWebpackPlugin from 'html-webpack-plugin';
import CopyWebpackPlugin from 'copy-webpack-plugin';

const appDir = path.resolve(__dirname, './src');
const distDir = path.resolve(__dirname, './dist');

module.exports = {
    entry: [
        appDir + '/main.js'
    ],
    output: {
        path: distDir,
        filename: 'main.js',
        publicPath: '/'
    },
    devServer: {
        contentBase: distDir,
        inline: true,
        port: 3000,
        compress: true,
        disableHostCheck: true
    },
    plugins: [
        new HtmlWebpackPlugin({
            template: path.resolve('src', 'index.html'),
            inject: 'body',
            filename: 'index.html'
        }),
        new CopyWebpackPlugin([
                {
                    from: 'src/**/*.html',
                    to: '.',
                    flatten: true
                },
            ],
            {
                copyUnmodified: true
            }
        )
    ],
    module: {
        loaders: [

        ]
    }
};
