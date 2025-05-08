exports.execute = async (args) => {
    // args => https://egomobile.github.io/vscode-powertools/api/interfaces/contracts.workspacecommandscriptarguments.html

    // s. https://code.visualstudio.com/api/references/vscode-api
    //#region includes
    const vscode = args.require('vscode');
    const helpers = args.require('vscode-helpers');
    const session = helpers.SESSION;

    const fs = args.require('fs-extra');
    const path = args.require('path');
    const moment = args.require('moment');

    const root = vscode.workspace.rootPath;
    const log_path = path.join(root, '.vscode/vscode-rewst-CICD/cmds/cmds.log')
    const config_path = path.join(root, '.vscode/vscode-rewst-CICD/config.json')
    //#endregion

    //#region logs
    const LOGGER = helpers.createLogger((log) => {
        fs.appendFileSync(log_path, `${moment.utc()}:${log.message}\r\n`, 'utf8');

    });
    session.log = (...args) => LOGGER.info(args);
    session.info = vscode.window.showInformationMessage;
    session.warning = vscode.window.showWarningMessage;
    session.error = vscode.window.showErrorMessage;

    const log = session.log



    //#endregion

    //#region config
    const config = async () => fs.readJson(config_path).catch(err => {
        log(err)
        return 0
    });

    if (await config() === 0) {
        log("STOPPING")
        return
    }

    const get_company_config = async (document) => {
        const path = relative_path(document.uri)
        const parts = path.split('\\')
        const folder = parts[1]
        const company_config = (await config()).RewstInstances[folder] || 0
        log("Company config", folder)
        if (company_config === 0)
            session.warning(`No company config for folder: ${folder}`)
        return company_config
    };

    //#endregion

    //#region helpers
    const relative_path = (path) => vscode.Uri.parse(path).fsPath.replace(root, ".");

    const associate_template = async (document, template_guid) => {
        log("associate lmbda")
        const first_line = document.lineAt(0);
        log(first_line.text)

        const new_line = first_line.text.replace("create template", `export ${template_guid}`)
        const edit = new vscode.WorkspaceEdit();
        edit.replace(
            document.uri,
            first_line.range,
            new_line
        );

        vscode.workspace.applyEdit(edit)
    }

    const get_associate_template = async (document) => {
        log("get_associate_template lmbda")
        const guid_regex = /(\w{8}-\w{4}-\w{4}-\w{4}-\w{12})/g;
        const first_line = document.lineAt(0);
        const template_guid = first_line.text.match(guid_regex)?.[0] ?? 0;
        log(template_guid)
        return template_guid
    }

    const get_name = (document) => {
        return relative_path(document.uri.path)
    };

    session.name = get_name;

    //#endregion

    //#region request

    const rewstFetch = async (company_config, method, body = {}) => await fetch(company_config.Webhook, {
        method: method,
        headers: { //headers
            'Content-Type': 'application/json; charset=utf8',
            "x-rewst-secret": company_config.Secret
        },
        body: JSON.stringify(body)
    })
        .then(response => response.json())
        .then((data) => { log(JSON.stringify(data)); return data.result; })

    //#endregion

    //#region exports
    session.export_template = async ({ document, progress, token, ...params }) => {
        log("export function")

        const first_line = await document.lineAt(0);
        if (!first_line.text.includes("export")) {
            const message = "'export' directive not present in first line of file, EXITING";
            log(message)
            session.error(message)
            return
        }

        const template_guid = await get_associate_template(document)

        if (template_guid === 0) {
            const message = 'no associated guid found, EXITING'
            log(message)
            session.error(message)
            return
        }

        const company_config = await get_company_config(document)

        if (company_config === 0) {
            const message = 'no company config'
            log(message)
            return
        }

        const name = get_name(document)
        const base64Content = btoa(document.getText())
        const body = { //body
            "method": "export",
            "template_name": name,
            "template": base64Content,
            "template_guid": template_guid,
            "ps": company_config.PS,
            ...params
        };
        // log(JSON.stringify(body))

        if (token.isCancellationRequested) { return }

        progress.report({ message: `Awaiting Rewst's Response`, increment: 80 });

        const res = await rewstFetch(company_config, 'POST', body)

        log(JSON.stringify(res))

        if (res?.success || 0) {
            const message = "Successfully exported document"
            session.info(message);
        } else {
            const message = `Server responded with error. Please check logs at ${log_path}`
            log(message)
            session.error(message)
        }
    }

    session.create_template = async ({ document, progress, token, ...params }) => {
        log("create function")

        const first_line = await document.lineAt(0);
        if (!first_line.text.includes("create template")) {

            const message = "Create template directive not present in file, EXITING"
            log(message)
            session.warning(message)

            return
        }

        const company_config = await get_company_config(document)

        if (company_config === 0) {
            log('No Company config')
            return
        }

        const name = get_name(document)
        const base64Content = btoa(document.getText())
        const body = { //body
            "method": "create",
            "template_name": name,
            "template": base64Content,
            "ps": company_config.PS,
            ...params
        };
        // log(JSON.stringify(body))


        if (token.isCancellationRequested) { return }

        progress.report({ message: `Awaiting Rewst's Response`, increment: 80 });
        const res = await rewstFetch(company_config, 'POST', body)

        log(JSON.stringify(res))


        if (res?.success || 0) {
            const message = "Successfully created template"
            session.info(message);
            const template_guid = res.template_guid
            associate_template(document, template_guid)
        } else {
            const message = `Server responded with error. Please check logs at ${log_path}`
            log(message)
            session.error(message)
        }
    }

    //#endregion

    //#region done
    session.info("Loaded Rewst Template CICD Startup")
    log("Loaded STARTUP")

    return
};