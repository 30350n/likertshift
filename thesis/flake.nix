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
                (texlive.combine {
                    inherit (texlive) scheme-basic;
                    inherit
                        (texlive)
                        booktabs
                        caption
                        cite
                        collection-fontsrecommended
                        comment
                        csquotes
                        enumitem
                        eurosym
                        koma-script
                        latexmk
                        microtype
                        multirow
                        pdflscape
                        pgf
                        setspace
                        siunitx
                        tools
                        urlbst
                        wrapfig
                        xfrac
                        ;
                })
            ];
        };
    };
}
