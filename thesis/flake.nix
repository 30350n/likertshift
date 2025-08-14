{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    };

    outputs = {
        self,
        nixpkgs,
    }: let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
    in {
        devShells.${system}.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
                pdfpc
                (texlive.combine {
                    inherit (texlive) scheme-basic;
                    inherit
                        (texlive)
                        adjustbox
                        anyfontsize
                        beamer
                        booktabs
                        caption
                        catchfile
                        cite
                        collection-fontsrecommended
                        comment
                        csquotes
                        enumitem
                        eurosym
                        fontaxes
                        fontspec
                        hyperxmp
                        ifmtarg
                        koma-script
                        latexmk
                        microtype
                        multirow
                        pdflscape
                        pdfpc
                        pgf
                        roboto
                        setspace
                        siunitx
                        tools
                        tuda-ci
                        urlbst
                        wrapfig
                        xcharter
                        xfrac
                        xkeyval
                        xstring
                        ;
                })
            ];
        };
    };
}
