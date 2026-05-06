{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: 
      let 
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in {

        packages.x86_64-linux.default = pkgs.hello;

        devShell.x86_64-linux = pkgs.mkShell{
            buildInputs = with pkgs; [
                hello
                ripgrep
            ];
        };
      };
}
