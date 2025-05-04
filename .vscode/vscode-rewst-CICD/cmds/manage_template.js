exports.execute = async (args) => {
    // args => https://egomobile.github.io/vscode-powertools/api/interfaces/contracts.workspacecommandscriptarguments.html

    // s. https://code.visualstudio.com/api/references/vscode-api

    const helpers = args.require('vscode-helpers');
    const vscode = args.require('vscode');
    const session = helpers.SESSION;
    const log = session.log;

    const command = args.options["command"]

    log(`started ${command}`)
    const fsPath = args.file?.fsPath || vscode.window?.activeTextEditor?.document?.fileName
    log(fsPath)

    const document = await vscode.workspace.openTextDocument(fsPath);



    await vscode.window.withProgress({
        location: vscode.ProgressLocation.Notification,
        title: `${command}:`,
        cancellable: true
    }, async (progress, token) => {
        // Your async operations here
        token.onCancellationRequested(() => {
            console.log("User canceled the operation");
        });

        const params = {
            document: document,
            progress: progress,
            token: token
        }

        await session[command](params)
    });
};
