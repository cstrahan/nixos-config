self: super:

{
  pragmatapro = self.callPackage ../packages/pragmatapro.nix { };
  vimHuge = self.callPackage ../packages/vim-huge.nix { };
  kdbplus = super.kdbplus.overrideAttrs (_: {
    src = self.requireFile {
      message = ''
        Nix can't download kdb+ for you automatically. Go to
        http://kx.com and download the free, 32-bit version for
        Linux. Then run "nix-prefetch-url file:///linux.zip" in the
        directory where you saved it. Note you need version 3.3.
      '';
      name   = "linux.zip";
      sha256 = "0pvndlqspxrzp5fbx2b6qw8cld8c8hcz5kavmgvs9l4s3qv9ab51";
    };
  });
}
