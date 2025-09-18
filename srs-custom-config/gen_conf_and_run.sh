#!/usr/bin/env bash

set -e

echo "🚀 Starting SRS with dynamic config generation..."

# Paths
srs_home=/usr/local/srs
config_generator_home=/tmp/srs-config
dest_conf_path=${srs_home}/conf/srs.conf

function install_python_deps() {
    echo "📦 Installing Python dependencies..."
    cd ${config_generator_home}/gen_conf

    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi

    # Activate and install dependencies
    source venv/bin/activate
    pip install jinja2

    cd -
}

function gen_conf() {
    echo "🔧 Generating SRS configuration from environment variables..."
    cd ${config_generator_home}

    cd gen_conf
    source venv/bin/activate
    python3 ./gen_conf.py
    cd -

    # Copy generated config to SRS location
    cp output/srs.conf ${dest_conf_path}

    echo "📄 Generated config:"
    cat ${dest_conf_path}
}

function run_srs() {
    echo "🎬 Starting SRS server..."
    cd ${srs_home}
    ./objs/srs -c ${dest_conf_path}
}

# Main execution
install_python_deps
gen_conf
run_srs