function setRange(rng)

set(0, 'currentfigure', 1);
h = get(1,'Children');

pre = findobj('UserData','pre_ax');
for i=1:length(pre);set(pre(i),'clim',rng);end
pre = findobj('UserData','copy_pre_ax');
for i=1:length(pre);set(pre(i),'clim',rng);end
push = findobj('UserData','push_ax');
for i=1:length(push);set(push(i),'clim',rng);end
push = findobj('UserData','copy_push_ax');
for i=1:length(push);set(push(i),'clim',rng);end
res = findobj('UserData','res_ax');
set(res,'ylim',rng);

if isunix
    cb = findobj('UserData','disp_cb');
    set(cb,'Limits',rng);
end

