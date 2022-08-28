/**
 * Typescript benchmark code generator.
 */
const {existsSync, mkdirSync, writeFileSync} = require('fs');
const {dirname} = require('path');

function mkdir(d) {
    if (!existsSync(dirname(d))) {
        mkdir(dirname(d))
    }
    if (!existsSync(d)) {
        mkdirSync(d)
    }
}

function write(to, content) {
    mkdir(dirname(to))
    writeFileSync(to, content)
}

const featureNames = [
    'billing',
    'compute',
    'datastore',
    'functions',
    'logging',
    'monitoring',
    'networking',
    'registry',
    'storage',
    'support',
]

class Generator {
    static STYLES = [
        'ts_project',
        'ts_project_rbe',
        'ts_project_worker',
        'ts_project_sandboxed_worker',
        'ts_project_swc',
        'ts_project_swc_rbe',
        'ts_project_worker_swc',
        'ts_project_sandboxed_worker_swc',
        'ts_project_rules_nodejs',
        'ts_project_rules_nodejs_swc',
        'ts_library',
        'ts_library_rbe',
        'tsc',
    ]

    constructor(style, outputDir, numFeatures, modulesPerFeature, componentsPerModule, symbolsPerComponent) {
        if (!Generator.STYLES.includes(style)) {
            console.error(`expected style to be one of [${Generator.STYLES.join(", ")}] but got '${style}'`);
            process.exit(1)
        }
        this.style = style
        this.outputDir = outputDir
        this.numFeatures = numFeatures
        this.modulesPerFeature = modulesPerFeature
        this.componentsPerModule = componentsPerModule
        this.symbolsPerComponent = symbolsPerComponent
        this.cmpIdx = 0
    }

    generate() {
        const rootDeps = []
        for (let i=0; i<this.numFeatures; ++i) {
            this.generateFeature(featureNames[i])
            rootDeps.push(`//${this.outputDir}/${featureNames[i]}`)
        }

        if (this.style != 'tsc') {
            write(`${this.outputDir}/BUILD.bazel`, this._root_build(rootDeps))
        }
        write(`${this.outputDir}/tsconfig.json`, this._tsconfig())
    }

    generateFeature(name) {
        const featureModuleDeps = [];

        for (let modIdx = 0; modIdx < this.modulesPerFeature; modIdx++) {
            featureModuleDeps.push(`//${this.outputDir}/${name}/lib${modIdx}`);
            const tsFileAcc = [];

            for (let cmpIdx = 0; cmpIdx < this.componentsPerModule; cmpIdx++) {
                let fileName = `cmp${this.cmpIdx}/cmp${this.cmpIdx}.component.ts`
                let range1k = [...Array(this.symbolsPerComponent).keys()]
                let vars = range1k.map(f => `export const a${f}: number = ${f}`).join('\n')
                let sum = 'export const a = ' + range1k.map(f => `a${f}`).join('+')
                write(`${this.outputDir}/${name}/lib${modIdx}/${fileName}`, `${vars}\n${sum}\n`)
                tsFileAcc.push(fileName);
                this.cmpIdx++;
            }

            write(`${this.outputDir}/${name}/lib${modIdx}/index.ts`, tsFileAcc.map(
                (s, idx) => `import {a as val${idx}} from './${s.replace('.ts', '')}'`).join('\n'));

            // Write a BUILD file to build the lib
            if (this.style != 'tsc') {
                write(`${this.outputDir}/${name}/lib${modIdx}/BUILD.bazel`, `
# Generated BUILD file, see /generate.js
${this._load()}

package(default_visibility = ["//:__subpackages__"])
 
ts_project(
    name = "lib${modIdx}",
    srcs = [
        "index.ts",
        ${tsFileAcc.map(s => `"${s}"`).join(',\n        ')}
    ],
${this._ts_attributes()}
)
`);
            }
        }

        write(`${this.outputDir}/${name}/index.ts`, featureModuleDeps.map(f => f.split("/").pop()).map(f => `import {} from './${f}'`).join("\n"))

        // Write a BUILD file to build the feature
        if (this.style != 'tsc') {
            write(`${this.outputDir}/${name}/BUILD.bazel`, `
# Generated BUILD file, see /generate.js
${this._load()}

package(default_visibility = ["//:__subpackages__"])

ts_project(
    name = "${name}",
    srcs = [
        "index.ts",
    ],
${this._ts_attributes()}
    deps = [
        ${featureModuleDeps.map(s => `"${s}"`).join(',\n        ')}
    ],
)
`);
        }
    }

    _load() {
        switch (this.style) {
            case 'ts_project':
            case 'ts_project_rbe':
            case 'ts_project_worker':
            case 'ts_project_sandboxed_worker':
                return [
                    'load("@aspect_rules_ts//ts:defs.bzl", "ts_project")',
                    'load("@aspect_rules_js//js:defs.bzl", "js_library")',
                ].join("\n")

            case 'ts_project_swc':
            case 'ts_project_swc_rbe':
            case 'ts_project_worker_swc':
            case 'ts_project_sandboxed_worker_swc':
                return [
                    'load("@aspect_rules_ts//ts:defs.bzl", "ts_project")',
                    'load("@aspect_rules_js//js:defs.bzl", "js_library")',
                    'load("@aspect_rules_swc//swc:defs.bzl", "swc_transpiler")',
                ].join("\n")

            case 'ts_project_rules_nodejs':
                return [
                    'load("@npm//@bazel/typescript:index.bzl", "ts_project")',
                    'load("@npm//@bazel/typescript:index.bzl", js_library = "ts_project")',
                ].join("\n")

            case 'ts_project_rules_nodejs_swc':
                return [
                    'load("@npm//@bazel/typescript:index.bzl", "ts_project")',
                    'load("@aspect_rules_swc//swc:defs.bzl", "swc_transpiler")',
                ].join("\n")

            case 'ts_library':
            case 'ts_library_rbe':
                return [
                    'load("@npm_tslibrary//@bazel/concatjs:index.bzl", ts_project = "ts_library")',
                    'load("@npm_tslibrary//@bazel/concatjs:index.bzl", js_library = "ts_library")',
                    'load("@aspect_rules_swc//swc:defs.bzl", "swc_transpiler")',
                ].join("\n")

            default:
                console.error("Unhandled style")
                process.exit(1)
        }
    }

    _tsconfig() {
        let tsconfig = {
            "compilerOptions": {
                "declaration": true,
                "baseUrl": ".",
                "rootDirs": ["."],
            }
        }
        if (this.style == 'ts_project_rules_nodejs' || this.style == 'ts_project_rules_nodejs_swc') {
            tsconfig.compilerOptions.rootDirs = [
                ".",
                `../bazel-out/darwin-fastbuild/bin/${this.style}`,
                `../bazel-out/darwin_arm64-fastbuild/bin/${this.style}`,
                `../bazel-out/k8-fastbuild/bin/${this.style}`,
            ]
        }
        return JSON.stringify(tsconfig, null, 2);
    }

    _root_build(rootDeps) {
        switch (this.style) {
            case 'ts_project':
            case 'ts_project_rbe':
            case 'ts_project_worker':
            case 'ts_project_sandboxed_worker':
            case 'ts_project_swc':
            case 'ts_project_swc_rbe':
            case 'ts_project_worker_swc':
            case 'ts_project_sandboxed_worker_swc':
                return `
# Generated BUILD file, see /generate.js
load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_to_bin")
${this._load()}

package(default_visibility = ["//:__subpackages__"])

copy_to_bin(
    name = "tsconfig",
    srcs = ["tsconfig.json"],
)

js_library(
    name = "devserver",
    deps = [
${rootDeps.map(d => `        \"${d}\",`).join("\n")}
    ],
)
`

            case 'ts_project_rules_nodejs':
            case 'ts_project_rules_nodejs_swc':
            case 'ts_library':
            case 'ts_library_rbe':
                return `
# Generated BUILD file, see /generate.js
${this._load()}
exports_files(["tsconfig.json"])
ts_project(
    name = "devserver",
    srcs = [],
    deps = [
${rootDeps.map(d => `        \"${d}\",`).join("\n")}
    ],
    tsconfig = "//${this.outputDir}:tsconfig.json",
)
`
            default:
                console.error("Unhandled style")
                process.exit(1)
        }
    }

    _ts_attributes() {
        let attrs = []
        switch (this.style) {
            case 'ts_project':
            case 'ts_project_rbe':
                attrs.push(`    tsconfig = "//${this.outputDir}:tsconfig",`)
                attrs.push('    declaration = True,')
                attrs.push('    supports_workers = False,')
                break;

            case 'ts_project_worker':
            case 'ts_project_sandboxed_worker':
                attrs.push(`    tsconfig = "//${this.outputDir}:tsconfig",`)
                attrs.push('    declaration = True,')
                attrs.push('    supports_workers = True,')
                break;

            case 'ts_project_swc':
            case 'ts_project_swc_rbe':
                attrs.push(`    tsconfig = "//${this.outputDir}:tsconfig",`)
                attrs.push('    declaration = True,')
                attrs.push('    transpiler = swc_transpiler,')
                attrs.push('    supports_workers = False,')
                break;

            case 'ts_project_worker_swc':
            case 'ts_project_sandboxed_worker_swc':
                attrs.push(`    tsconfig = "//${this.outputDir}:tsconfig",`)
                attrs.push('    declaration = True,')
                attrs.push('    transpiler = swc_transpiler,')
                attrs.push('    supports_workers = True,')
                break;

            case 'ts_project_rules_nodejs':
                attrs.push(`    tsconfig = "//${this.outputDir}:tsconfig.json",`)
                attrs.push('    declaration = True,')
                break;

            case 'ts_project_rules_nodejs_swc':
                attrs.push(`    tsconfig = "//${this.outputDir}:tsconfig.json",`)
                attrs.push('    declaration = True,')
                attrs.push('    transpiler = swc_transpiler,')
                break;

            case 'ts_library':
            case 'ts_library_rbe':
                attrs.push(`    tsconfig = "//${this.outputDir}:tsconfig.json",`)
                break;

            default:
                console.error("Unhandled style")
                process.exit(1)
        }
        return attrs.join("\n");
    }
}

function main(args) {
    if (args.length < 2) {
        console.error('Usage: node generator.js [style] [outputDir] [numFeatures] [modulesPerFeature] [componentsPerModule] [symbolsPerComponent]')
        process.exit(1)
    }
    const style = args[0]
    const outputDir = args[1]
    const numFeatures = parseInt(args[2]) || 10
    const modulesPerFeature = parseInt(args[3]) || 2
    const componentsPerModule = parseInt(args[4]) || 2
    const symbolsPerComponent = parseInt(args[5]) || 1000
    
    const generator = new Generator(style, outputDir, numFeatures, modulesPerFeature, componentsPerModule, symbolsPerComponent);
    console.log(`Generating ${style} benchmark in ${outputDir}`)
    generator.generate();
}

main(process.argv.slice(2))
