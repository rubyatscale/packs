use magnus::{function, prelude::*, Error, Ruby};

use packs::packs;

fn run_check(files: Vec<String>) -> bool {
    let configuration = packs::configuration();
    let result = packs::check(&configuration, files);
    match result {
        Ok(_) => true,
        Err(_e) => false,
    }
}

fn run_validate() -> bool {
    let configuration = packs::configuration();
    let result = packs::validate(&configuration);
    match result {
        Ok(_) => true,
        Err(_e) => false,
    }
}

fn run_update() -> bool {
    let configuration = packs::configuration();
    let result = packs::update(&configuration);
    match result {
        Ok(_) => true,
        Err(_e) => false,
    }
}

fn run_lint_package_yml_files() -> bool {
    let configuration = packs::configuration();
    packs::lint_package_yml_files(&configuration);
    true
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("PacksRust")?;
    module.define_singleton_method("check", function!(run_check, 1))?;
    module.define_singleton_method("validate", function!(run_validate, 0))?;
    module.define_singleton_method("update", function!(run_update, 0))?;
    module.define_singleton_method(
        "lint_package_yml_files",
        function!(run_lint_package_yml_files, 0),
    )?;

    Ok(())
}
