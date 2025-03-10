#squeue_format_short="%.18i %.9P %.8j %.8u %.2t %.10M %.6D %.16b %.20R"
#squeue_format_long="%.18i %.9P %.20j %.8u %.2t %.10M %.1D %.10R %.2C %.5m %24b"'

squeue_format_short="JobArrayID:.19 ,Partition:.9 ,Name:.20 ,UserName:.8 ,StateCompact:.2 ,TimeUsed:.10 ,NumNodes:.1 ,tres-per-node:.16 ,ReasonList:.10"
alias squ='squeue -O "${squeue_format_short}"'
alias squu='squeue -a -u ${USER} --format="${squeue_format_short}"'
alias squa='squeue -a --format="${squeue_format_short}"'

function squl() {
    squeue "$@" -O "JobArrayID:.19 ,Partition:.9 ,Name:.20 ,UserName:.8 ,StateCompact:.2 ,TimeUsed:.10 ,NumNodes:.1 ,ReasonList:.10 ,tres-alloc:80" | sed -e "s/gres\/local//g" -e "s/gres\///g"
}
alias squlu='squl -u ${USER}'
alias squla='squl -a'
